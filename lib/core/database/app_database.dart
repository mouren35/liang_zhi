import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get sortOrder => integer().withDefault(const Constant<int>(0))();
  BoolColumn get isSystem => boolean().withDefault(const Constant<bool>(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Locations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get sortOrder => integer().withDefault(const Constant<int>(0))();
  BoolColumn get isSystem => boolean().withDefault(const Constant<bool>(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get brand => text().withLength(min: 1, max: 100).nullable()();
  TextColumn get specification => text().withLength(min: 1, max: 100).nullable()();
  TextColumn get imageLocalPath => text().nullable()();
  TextColumn get imageRemoteUrl => text().nullable()();
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get locationId =>
      text().nullable().references(Locations, #id, onDelete: KeyAction.setNull)();
  RealColumn get quantity => real().check(
    const CustomExpression<bool>('quantity > 0'),
  )();
  TextColumn get unit => text().withLength(min: 1, max: 20).withDefault(const Constant('份'))();
  TextColumn get expiryInputType => text().check(
    const CustomExpression<bool>(
      "expiry_input_type IN ('direct', 'production_shelf_life')",
    ),
  )();
  TextColumn get productionDate => text().nullable()();
  IntColumn get shelfLifeValue => integer().nullable().check(
    const CustomExpression<bool>('shelf_life_value IS NULL OR shelf_life_value > 0'),
  )();
  TextColumn get shelfLifeUnit => text().nullable().check(
    const CustomExpression<bool>(
      "shelf_life_unit IS NULL OR shelf_life_unit IN ('day', 'month', 'year')",
    ),
  )();
  TextColumn get expiryDate => text()();
  IntColumn get reminderDaysBefore => integer().nullable().check(
    const CustomExpression<bool>(
      'reminder_days_before IS NULL OR reminder_days_before >= 0',
    ),
  )();
  TextColumn get status => text().check(
    const CustomExpression<bool>("status IN ('active', 'consumed', 'discarded')"),
  )();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
    "CHECK (image_remote_url IS NULL OR image_remote_url LIKE 'https://%')",
    "CHECK ((expiry_input_type = 'direct' AND production_date IS NULL "
        'AND shelf_life_value IS NULL AND shelf_life_unit IS NULL) '
        "OR (expiry_input_type = 'production_shelf_life' AND production_date IS NOT NULL "
        'AND shelf_life_value IS NOT NULL AND shelf_life_unit IS NOT NULL))',
  ];
}

class BarcodeProductCache extends Table {
  TextColumn get barcode => text()();
  TextColumn get lookupStatus => text().check(
    const CustomExpression<bool>("lookup_status IN ('found', 'not_found')"),
  )();
  TextColumn get productName => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get quantityText => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get categoryTagsJson => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('open_food_facts'))();
  IntColumn get fetchedAt => integer()();
  IntColumn get expiresAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{barcode};
}

@DriftDatabase(tables: <Type>[Categories, Locations, Foods, BarcodeProductCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      // Schema migrations are appended here and covered by migration tests.
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _createIndices();
    },
  );

  Future<void> ensureOpen() async {
    await customSelect('SELECT 1').getSingle();
  }

  Future<void> _createIndices() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_active_expiry '
      'ON foods(status, deleted_at, expiry_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_updated_at ON foods(updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_category_id ON foods(category_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_location_id ON foods(location_id)',
    );
    await customStatement('CREATE INDEX IF NOT EXISTS idx_foods_barcode ON foods(barcode)');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    final File databaseFile = File(path.join(documents.path, 'liangzhi.sqlite'));
    return NativeDatabase.createInBackground(databaseFile);
  });
}
