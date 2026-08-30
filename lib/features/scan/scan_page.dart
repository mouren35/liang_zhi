import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/platform/system_settings_service.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/models/product_barcode.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';
import 'package:liangzhi/shared/widgets/responsive_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final class ScanDetection {
  const ScanDetection({required this.rawValue, required this.format});

  final String? rawValue;
  final ProductBarcodeFormat format;
}

typedef ScannerViewBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<ScanDetection> onDetected,
    );

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({
    required this.onProductFound,
    required this.onManualFallback,
    this.scannerBuilder,
    this.onOpenSystemSettings = SystemSettingsService.openAppSettings,
    super.key,
  });

  final Future<void> Function(ProductLookupResult result) onProductFound;
  final Future<void> Function(String barcode) onManualFallback;
  final ScannerViewBuilder? scannerBuilder;
  final Future<void> Function() onOpenSystemSettings;

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  MobileScannerController? _controller;
  String? _processingBarcode;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    if (widget.scannerBuilder == null) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const <BarcodeFormat>[
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
        ],
      );
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('扫码添加', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text('将一维商品条形码放入取景框；二维码不会用于商品查询。'),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.scannerBuilder?.call(context, _handleDetection) ?? _mobileScanner(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 48,
              child: Center(
                child: _processingBarcode != null
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text('正在查询商品信息…'),
                        ],
                      )
                    : Text(_feedback ?? '支持 EAN-8、EAN-13、UPC-A、UPC-E、Code 128'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileScanner() {
    return MobileScanner(
      controller: _controller,
      onDetect: (BarcodeCapture capture) {
        for (final Barcode barcode in capture.barcodes) {
          final ProductBarcodeFormat? format = productBarcodeFormatFromScanner(
            barcode.format,
          );
          if (format != null) {
            _handleDetection(
              ScanDetection(rawValue: barcode.rawValue, format: format),
            );
            return;
          }
        }
      },
      errorBuilder: (BuildContext context, MobileScannerException error) {
        if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
          return CameraPermissionDeniedView(
            onOpenSystemSettings: widget.onOpenSystemSettings,
          );
        }
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: Text(
              '相机暂时不可用，请稍后重试',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
      overlayBuilder: (BuildContext context, BoxConstraints constraints) {
        return IgnorePointer(
          child: Center(
            child: Container(
              width: constraints.maxWidth * 0.82,
              height: 132,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDetection(ScanDetection detection) async {
    if (_processingBarcode != null) {
      return;
    }
    final ProductBarcode? barcode = ProductBarcode.tryParse(
      detection.rawValue,
      detection.format,
    );
    if (barcode == null) {
      setState(() => _feedback = '未识别到有效的一维商品条形码');
      return;
    }
    setState(() {
      _processingBarcode = barcode.value;
      _feedback = null;
    });
    try {
      final ProductLookupResult result = await ref
          .read(productLookupRepositoryProvider)
          .lookup(barcode);
      if (!mounted) {
        return;
      }
      if (result.isFound) {
        await widget.onProductFound(result);
      } else {
        await widget.onManualFallback(barcode.value);
      }
    } on Object {
      if (mounted) {
        await widget.onManualFallback(barcode.value);
      }
    } finally {
      if (mounted) {
        setState(() => _processingBarcode = null);
      }
    }
  }
}

ProductBarcodeFormat? productBarcodeFormatFromScanner(BarcodeFormat format) {
  return switch (format) {
    BarcodeFormat.ean8 => ProductBarcodeFormat.ean8,
    BarcodeFormat.ean13 => ProductBarcodeFormat.ean13,
    BarcodeFormat.upcA => ProductBarcodeFormat.upcA,
    BarcodeFormat.upcE => ProductBarcodeFormat.upcE,
    BarcodeFormat.code128 => ProductBarcodeFormat.code128,
    _ => null,
  };
}

class CameraPermissionDeniedView extends StatelessWidget {
  const CameraPermissionDeniedView({
    required this.onOpenSystemSettings,
    super.key,
  });

  final Future<void> Function() onOpenSystemSettings;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, size: 48),
              const SizedBox(height: AppSpacing.sm),
              const Text('需要相机权限才能扫描条形码'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: onOpenSystemSettings,
                child: const Text('打开系统设置'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
