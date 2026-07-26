import 'package:drift/drift.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/database/default_data.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/shared/models/reference_item.dart';
import 'package:liangzhi/shared/repositories/reference_data_repository.dart';

final class LocalCategoryRepository implements CategoryRepository {
  const LocalCategoryRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<ReferenceItem>> getAll() async {
    try {
      final List<Category> rows =
          await (_database.select(_database.categories)
                ..where(($CategoriesTable table) => table.deletedAt.isNull())
                ..orderBy(<OrderClauseGenerator<$CategoriesTable>>[
                  ($CategoriesTable table) => OrderingTerm.asc(table.sortOrder),
                  ($CategoriesTable table) => OrderingTerm.asc(table.createdAt),
                ]))
              .get();
      return List<ReferenceItem>.unmodifiable(
        rows.map(
          (Category row) =>
              ReferenceItem(id: row.id, name: row.name, isSystem: row.isSystem),
        ),
      );
    } on Object {
      throw const DatabaseUnavailableException();
    }
  }

  @override
  Future<ReferenceItem?> getDefault() async {
    return _findById(DefaultIds.categoryOther);
  }

  Future<ReferenceItem?> _findById(String id) async {
    final List<ReferenceItem> items = await getAll();
    return items.where((ReferenceItem item) => item.id == id).firstOrNull;
  }
}

final class LocalLocationRepository implements LocationRepository {
  const LocalLocationRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<ReferenceItem>> getAll() async {
    try {
      final List<Location> rows =
          await (_database.select(_database.locations)
                ..where(($LocationsTable table) => table.deletedAt.isNull())
                ..orderBy(<OrderClauseGenerator<$LocationsTable>>[
                  ($LocationsTable table) => OrderingTerm.asc(table.sortOrder),
                  ($LocationsTable table) => OrderingTerm.asc(table.createdAt),
                ]))
              .get();
      return List<ReferenceItem>.unmodifiable(
        rows.map(
          (Location row) =>
              ReferenceItem(id: row.id, name: row.name, isSystem: row.isSystem),
        ),
      );
    } on Object {
      throw const DatabaseUnavailableException();
    }
  }

  @override
  Future<ReferenceItem?> getDefault() async {
    final List<ReferenceItem> items = await getAll();
    return items.where((ReferenceItem item) => item.id == DefaultIds.locationOther).firstOrNull;
  }
}
