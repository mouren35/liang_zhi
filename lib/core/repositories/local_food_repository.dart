import 'package:drift/drift.dart';
import 'package:liangzhi/core/database/app_database.dart' as database;
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/shared/models/food.dart' as domain;
import 'package:liangzhi/shared/repositories/food_repository.dart';

final class LocalFoodRepository implements FoodRepository {
  const LocalFoodRepository(this._database);

  final database.AppDatabase _database;

  @override
  Future<void> add(domain.Food food) async {
    try {
      await _database.into(_database.foods).insert(_toCompanion(food));
    } on Object {
      throw const DataWriteException();
    }
  }

  @override
  Future<List<domain.Food>> getActiveFoods() async {
    try {
      final List<database.Food> rows = await _activeQuery().get();
      return List<domain.Food>.unmodifiable(rows.map(_toDomain));
    } on FormatException {
      throw const DataValidationException();
    } on AppException {
      rethrow;
    } on Object {
      throw const DatabaseUnavailableException();
    }
  }

  @override
  Stream<List<domain.Food>> watchActiveFoods() {
    return _activeQuery().watch().map((List<database.Food> rows) {
      try {
        return List<domain.Food>.unmodifiable(rows.map(_toDomain));
      } on FormatException {
        throw const DataValidationException();
      }
    });
  }

  @override
  Future<domain.Food> getById(String id) async {
    try {
      final database.Food? row =
          await (_database.select(_database.foods)..where(
                (database.$FoodsTable table) => table.id.equals(id) & table.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (row == null) {
        throw const DataNotFoundException();
      }
      return _toDomain(row);
    } on FormatException {
      throw const DataValidationException();
    } on AppException {
      rethrow;
    } on Object {
      throw const DatabaseUnavailableException();
    }
  }

  @override
  Future<void> update(domain.Food food) async {
    try {
      final int affected =
          await (_database.update(
            _database.foods,
          )..where((database.$FoodsTable table) => table.id.equals(food.id))).write(
            _toCompanion(food),
          );
      if (affected == 0) {
        throw const DataNotFoundException();
      }
    } on AppException {
      rethrow;
    } on Object {
      throw const DataWriteException();
    }
  }

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {
    try {
      final int timestamp = deletedAt.toUtc().millisecondsSinceEpoch;
      final int affected =
          await (_database.update(
            _database.foods,
          )..where((database.$FoodsTable table) => table.id.equals(id))).write(
            database.FoodsCompanion(
              deletedAt: Value<int>(timestamp),
              updatedAt: Value<int>(timestamp),
            ),
          );
      if (affected == 0) {
        throw const DataNotFoundException();
      }
    } on AppException {
      rethrow;
    } on Object {
      throw const DataWriteException();
    }
  }

  SimpleSelectStatement<database.$FoodsTable, database.Food> _activeQuery() {
    return _database.select(_database.foods)
      ..where(
        (database.$FoodsTable table) =>
            table.status.equals(domain.FoodStatus.active.storageValue) & table.deletedAt.isNull(),
      )
      ..orderBy(<OrderClauseGenerator<database.$FoodsTable>>[
        (database.$FoodsTable table) => OrderingTerm.asc(table.expiryDate),
        (database.$FoodsTable table) => OrderingTerm.asc(table.createdAt),
      ]);
  }
}

domain.Food _toDomain(database.Food row) {
  return domain.Food(
    id: row.id,
    barcode: row.barcode,
    name: row.name,
    brand: row.brand,
    specification: row.specification,
    imageLocalPath: row.imageLocalPath,
    imageRemoteUrl: row.imageRemoteUrl == null ? null : Uri.parse(row.imageRemoteUrl!),
    categoryId: row.categoryId,
    locationId: row.locationId,
    quantity: row.quantity,
    unit: row.unit,
    expiryInputType: domain.ExpiryInputType.fromStorage(row.expiryInputType),
    productionDate: row.productionDate == null ? null : domain.parseLocalDate(row.productionDate!),
    shelfLifeValue: row.shelfLifeValue,
    shelfLifeUnit: row.shelfLifeUnit == null
        ? null
        : domain.ShelfLifeUnit.fromStorage(row.shelfLifeUnit!),
    expiryDate: domain.parseLocalDate(row.expiryDate),
    reminderDaysBefore: row.reminderDaysBefore,
    status: domain.FoodStatus.fromStorage(row.status),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    deletedAt: row.deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
  );
}

database.FoodsCompanion _toCompanion(domain.Food food) {
  return database.FoodsCompanion(
    id: Value<String>(food.id),
    barcode: Value<String?>(food.barcode),
    name: Value<String>(food.name),
    brand: Value<String?>(food.brand),
    specification: Value<String?>(food.specification),
    imageLocalPath: Value<String?>(food.imageLocalPath),
    imageRemoteUrl: Value<String?>(food.imageRemoteUrl?.toString()),
    categoryId: Value<String?>(food.categoryId),
    locationId: Value<String?>(food.locationId),
    quantity: Value<double>(food.quantity),
    unit: Value<String>(food.unit),
    expiryInputType: Value<String>(food.expiryInputType.storageValue),
    productionDate: Value<String?>(
      food.productionDate == null ? null : domain.formatLocalDate(food.productionDate!),
    ),
    shelfLifeValue: Value<int?>(food.shelfLifeValue),
    shelfLifeUnit: Value<String?>(food.shelfLifeUnit?.storageValue),
    expiryDate: Value<String>(domain.formatLocalDate(food.expiryDate)),
    reminderDaysBefore: Value<int?>(food.reminderDaysBefore),
    status: Value<String>(food.status.storageValue),
    createdAt: Value<int>(food.createdAt.millisecondsSinceEpoch),
    updatedAt: Value<int>(food.updatedAt.millisecondsSinceEpoch),
    deletedAt: Value<int?>(food.deletedAt?.millisecondsSinceEpoch),
  );
}
