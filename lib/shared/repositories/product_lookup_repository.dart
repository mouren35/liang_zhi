import 'package:liangzhi/shared/models/product_barcode.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';

abstract interface class ProductLookupRepository {
  Future<ProductLookupResult> lookup(ProductBarcode barcode);
}
