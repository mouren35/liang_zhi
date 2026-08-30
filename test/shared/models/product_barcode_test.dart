import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/models/product_barcode.dart';

void main() {
  test('校验并规范化 EAN、UPC 和 Code 128', () {
    expect(
      ProductBarcode.tryParse(
        '96385074',
        ProductBarcodeFormat.ean8,
      )?.value,
      '96385074',
    );
    expect(
      ProductBarcode.tryParse(
        '6901234567892',
        ProductBarcodeFormat.ean13,
      )?.value,
      '6901234567892',
    );
    expect(
      ProductBarcode.tryParse(
        '036000291452',
        ProductBarcodeFormat.upcA,
      )?.value,
      '0036000291452',
    );
    expect(
      ProductBarcode.tryParse(
        '04252614',
        ProductBarcodeFormat.upcE,
      )?.value,
      '0042100005264',
    );
    expect(
      ProductBarcode.tryParse(
        ' ABC-123 ',
        ProductBarcodeFormat.code128,
      )?.value,
      'ABC-123',
    );
  });

  test('拒绝校验位错误、控制字符和错误格式', () {
    expect(
      ProductBarcode.tryParse('6901234567893', ProductBarcodeFormat.ean13),
      isNull,
    );
    expect(
      ProductBarcode.tryParse('ABC\n123', ProductBarcodeFormat.code128),
      isNull,
    );
    expect(
      ProductBarcode.tryParse('6901234567892', ProductBarcodeFormat.ean8),
      isNull,
    );
  });
}
