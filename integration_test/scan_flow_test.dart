import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/app_routes.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/features/scan/scan_page.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/product_barcode.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';
import 'package:liangzhi/shared/models/reference_item.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';
import 'package:liangzhi/shared/repositories/product_lookup_repository.dart';
import 'package:liangzhi/shared/repositories/reference_data_repository.dart';

import 'support/granted_notification_platform.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('受控条码完成远程命中、补充到期日期并保存', (
    WidgetTester tester,
  ) async {
    final _MemoryFoodRepository foods = _MemoryFoodRepository();
    final _ControlledProductLookupRepository products = _ControlledProductLookupRepository();
    final Widget app = ProviderScope(
      overrides: [
        foodRepositoryProvider.overrideWithValue(foods),
        categoryRepositoryProvider.overrideWithValue(
          const _CategoryRepository(),
        ),
        locationRepositoryProvider.overrideWithValue(
          const _LocationRepository(),
        ),
        productLookupRepositoryProvider.overrideWithValue(products),
        notificationPlatformProvider.overrideWithValue(
          const GrantedNotificationPlatform(),
        ),
      ],
      child: LiangZhiApp(
        config: AppConfig(
          environment: AppEnvironment.test,
          openFoodFactsBaseUri: Uri.parse('https://example.com'),
        ),
        router: createAppRouter(scannerBuilder: _controlledScanner),
      ),
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('扫码添加').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('emit-controlled-barcode')),
    );
    await tester.pumpAndSettle();

    expect(products.calls, 1);
    expect(find.text('测试牛奶'), findsOneWidget);
    expect(find.text('粮知牧场'), findsOneWidget);
    expect(find.text('250 ml'), findsOneWidget);

    final Finder expiryDate = find.byKey(
      const ValueKey<String>('expiry-date'),
    );
    await tester.ensureVisible(expiryDate);
    await tester.tap(expiryDate);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    final Finder save = find.byKey(const ValueKey<String>('save-food'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('测试牛奶'), findsOneWidget);
    expect(foods.saved, hasLength(1));
    expect(foods.saved.single.barcode, '6901234567892');
    expect(foods.saved.single.brand, '粮知牧场');
    expect(foods.saved.single.specification, '250 ml');
    expect(foods.saved.single.categoryId, DefaultIds.categoryDairy);
    await foods.close();
  });
}

Widget _controlledScanner(
  BuildContext context,
  ValueChanged<ScanDetection> onDetected,
) {
  return Center(
    child: FilledButton(
      key: const ValueKey<String>('emit-controlled-barcode'),
      onPressed: () => onDetected(
        const ScanDetection(
          rawValue: '6901234567892',
          format: ProductBarcodeFormat.ean13,
        ),
      ),
      child: const Text('识别测试条码'),
    ),
  );
}

final class _ControlledProductLookupRepository implements ProductLookupRepository {
  int calls = 0;

  @override
  Future<ProductLookupResult> lookup(ProductBarcode barcode) async {
    calls += 1;
    return ProductLookupResult.found(
      ProductSuggestion(
        barcode: barcode.value,
        name: '测试牛奶',
        brand: '粮知牧场',
        specification: '250 ml',
        categoryTags: const <String>['en:dairy-products'],
        suggestedCategoryId: DefaultIds.categoryDairy,
      ),
      source: ProductLookupSource.remote,
    );
  }
}

final class _MemoryFoodRepository implements FoodRepository {
  final List<Food> saved = <Food>[];
  final StreamController<List<Food>> _changes = StreamController<List<Food>>.broadcast();

  Future<void> close() => _changes.close();

  @override
  Future<void> add(Food food) async {
    saved.add(food);
    _changes.add(List<Food>.unmodifiable(saved));
  }

  @override
  Future<List<Food>> getActiveFoods() async => List<Food>.unmodifiable(saved);

  @override
  Future<Food> getById(String id) async => saved.singleWhere((Food food) => food.id == id);

  @override
  Future<void> softDelete(
    String id, {
    required DateTime deletedAt,
  }) async {}

  @override
  Future<void> update(Food food) async {}

  @override
  Stream<List<Food>> watchActiveFoods() async* {
    yield List<Food>.unmodifiable(saved);
    yield* _changes.stream;
  }
}

final class _CategoryRepository implements CategoryRepository {
  const _CategoryRepository();

  static const ReferenceItem dairy = ReferenceItem(
    id: DefaultIds.categoryDairy,
    name: '乳制品',
    isSystem: true,
  );
  static const ReferenceItem other = ReferenceItem(
    id: DefaultIds.categoryOther,
    name: '其他',
    isSystem: true,
  );

  @override
  Future<List<ReferenceItem>> getAll() async => const <ReferenceItem>[dairy, other];

  @override
  Future<ReferenceItem?> getDefault() async => other;
}

final class _LocationRepository implements LocationRepository {
  const _LocationRepository();

  static const ReferenceItem other = ReferenceItem(
    id: DefaultIds.locationOther,
    name: '其他',
    isSystem: true,
  );

  @override
  Future<List<ReferenceItem>> getAll() async => const <ReferenceItem>[other];

  @override
  Future<ReferenceItem?> getDefault() async => other;
}
