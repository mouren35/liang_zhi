import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/features/scan/scan_page.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/shared/models/product_barcode.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';
import 'package:liangzhi/shared/repositories/product_lookup_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  testWidgets('同一处理窗口连续识别只查询一次并传出命中结果', (
    WidgetTester tester,
  ) async {
    final Completer<ProductLookupResult> completer = Completer<ProductLookupResult>();
    final _FakeLookupRepository repository = _FakeLookupRepository(
      () => completer.future,
    );
    int foundCount = 0;
    await _pump(
      tester,
      repository: repository,
      page: ScanPage(
        scannerBuilder: _scannerButton,
        onProductFound: (ProductLookupResult result) async {
          foundCount += 1;
        },
        onManualFallback: (String barcode) async {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('emit-barcode')));
    await tester.pump();
    expect(repository.calls, 1);
    expect(find.text('正在查询商品信息…'), findsOneWidget);

    completer.complete(_found());
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(foundCount, 1);
  });

  testWidgets('未命中、离线和服务错误均进入带条码手动添加', (
    WidgetTester tester,
  ) async {
    for (final Future<ProductLookupResult> Function() response
        in <Future<ProductLookupResult> Function()>[
          () async => const ProductLookupResult.notFound(
            source: ProductLookupSource.remote,
          ),
          () async => throw const NetworkUnavailableException(),
          () async => throw const NetworkTimeoutException(),
          () async => throw const RemoteRateLimitedException(),
          () async => throw const RemoteServiceException(),
        ]) {
      String? fallbackBarcode;
      await _pump(
        tester,
        repository: _FakeLookupRepository(response),
        page: ScanPage(
          scannerBuilder: _singleScannerButton,
          onProductFound: (ProductLookupResult result) async {},
          onManualFallback: (String barcode) async {
            fallbackBarcode = barcode;
          },
        ),
      );

      await tester.tap(find.byKey(const ValueKey<String>('emit-barcode')));
      await tester.pumpAndSettle();
      expect(fallbackBarcode, '6901234567892');
    }
  });

  testWidgets('权限拒绝状态提供系统设置入口', (WidgetTester tester) async {
    int openCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CameraPermissionDeniedView(
          onOpenSystemSettings: () async {
            openCount += 1;
          },
        ),
      ),
    );

    expect(find.text('需要相机权限才能扫描条形码'), findsOneWidget);
    await tester.tap(find.text('打开系统设置'));
    await tester.pump();
    expect(openCount, 1);
  });

  test('二维码和其他格式不进入商品条码映射', () {
    expect(productBarcodeFormatFromScanner(BarcodeFormat.qrCode), isNull);
    expect(productBarcodeFormatFromScanner(BarcodeFormat.dataMatrix), isNull);
    expect(
      productBarcodeFormatFromScanner(BarcodeFormat.ean13),
      ProductBarcodeFormat.ean13,
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ProductLookupRepository repository,
  required ScanPage page,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productLookupRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pump();
}

Widget _scannerButton(
  BuildContext context,
  ValueChanged<ScanDetection> onDetected,
) {
  return Center(
    child: FilledButton(
      key: const ValueKey<String>('emit-barcode'),
      onPressed: () {
        const ScanDetection detection = ScanDetection(
          rawValue: '6901234567892',
          format: ProductBarcodeFormat.ean13,
        );
        onDetected(detection);
        onDetected(detection);
      },
      child: const Text('识别'),
    ),
  );
}

Widget _singleScannerButton(
  BuildContext context,
  ValueChanged<ScanDetection> onDetected,
) {
  return Center(
    child: FilledButton(
      key: const ValueKey<String>('emit-barcode'),
      onPressed: () => onDetected(
        const ScanDetection(
          rawValue: '6901234567892',
          format: ProductBarcodeFormat.ean13,
        ),
      ),
      child: const Text('识别'),
    ),
  );
}

ProductLookupResult _found() {
  return const ProductLookupResult.found(
    ProductSuggestion(
      barcode: '6901234567892',
      name: '牛奶',
      categoryTags: <String>['en:dairy-products'],
      suggestedCategoryId: DefaultIds.categoryDairy,
    ),
    source: ProductLookupSource.remote,
  );
}

final class _FakeLookupRepository implements ProductLookupRepository {
  _FakeLookupRepository(this.response);

  final Future<ProductLookupResult> Function() response;
  int calls = 0;

  @override
  Future<ProductLookupResult> lookup(ProductBarcode barcode) {
    calls += 1;
    return response();
  }
}
