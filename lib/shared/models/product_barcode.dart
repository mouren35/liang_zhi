enum ProductBarcodeFormat { ean8, ean13, upcA, upcE, code128 }

final class ProductBarcode {
  const ProductBarcode._(this.value, this.format);

  final String value;
  final ProductBarcodeFormat format;

  static ProductBarcode? tryParse(
    String? rawValue,
    ProductBarcodeFormat format,
  ) {
    final String raw = rawValue?.trim() ?? '';
    return switch (format) {
      ProductBarcodeFormat.ean8 => _numeric(raw, 8, format),
      ProductBarcodeFormat.ean13 => _numeric(raw, 13, format),
      ProductBarcodeFormat.upcA => _upcA(raw),
      ProductBarcodeFormat.upcE => _upcE(raw),
      ProductBarcodeFormat.code128 => _code128(raw),
    };
  }

  static ProductBarcode? _numeric(
    String raw,
    int length,
    ProductBarcodeFormat format,
  ) {
    if (raw.length != length || !RegExp(r'^\d+$').hasMatch(raw) || !_hasValidGtinCheckDigit(raw)) {
      return null;
    }
    return ProductBarcode._(raw, format);
  }

  static ProductBarcode? _upcA(String raw) {
    if (raw.length != 12 || !RegExp(r'^\d{12}$').hasMatch(raw) || !_hasValidGtinCheckDigit(raw)) {
      return null;
    }
    return ProductBarcode._('0$raw', ProductBarcodeFormat.upcA);
  }

  static ProductBarcode? _upcE(String raw) {
    if (!RegExp(r'^[01]\d{7}$').hasMatch(raw)) {
      return null;
    }
    final String numberSystem = raw[0];
    final String checkDigit = raw[7];
    final List<String> digits = raw.substring(1, 7).split('');
    final String manufacturer;
    final String product;
    switch (digits[5]) {
      case '0' || '1' || '2':
        manufacturer = '${digits[0]}${digits[1]}${digits[5]}00';
        product = '00${digits[2]}${digits[3]}${digits[4]}';
      case '3':
        manufacturer = '${digits[0]}${digits[1]}${digits[2]}00';
        product = '000${digits[3]}${digits[4]}';
      case '4':
        manufacturer = '${digits[0]}${digits[1]}${digits[2]}${digits[3]}0';
        product = '0000${digits[4]}';
      default:
        manufacturer = '${digits[0]}${digits[1]}${digits[2]}${digits[3]}${digits[4]}';
        product = '0000${digits[5]}';
    }
    final String upcA = '$numberSystem$manufacturer$product$checkDigit';
    if (!_hasValidGtinCheckDigit(upcA)) {
      return null;
    }
    return ProductBarcode._('0$upcA', ProductBarcodeFormat.upcE);
  }

  static ProductBarcode? _code128(String raw) {
    if (raw.isEmpty || raw.length > 80 || raw.runes.any((int rune) => rune < 32 || rune == 127)) {
      return null;
    }
    return ProductBarcode._(raw, ProductBarcodeFormat.code128);
  }
}

bool _hasValidGtinCheckDigit(String value) {
  final List<int> digits = value.codeUnits.map((int value) => value - 0x30).toList(growable: false);
  final int checkDigit = digits.last;
  int sum = 0;
  for (int index = digits.length - 2, position = 0; index >= 0; index--, position++) {
    sum += digits[index] * (position.isEven ? 3 : 1);
  }
  return (10 - (sum % 10)) % 10 == checkDigit;
}
