import 'package:liangzhi/shared/models/reference_item.dart';

abstract interface class CategoryRepository {
  Future<List<ReferenceItem>> getAll();

  Future<ReferenceItem?> getDefault();
}

abstract interface class LocationRepository {
  Future<List<ReferenceItem>> getAll();

  Future<ReferenceItem?> getDefault();
}
