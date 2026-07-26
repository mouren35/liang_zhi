import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('隔离数据库可以打开并创建完整表集合', () async {
    await database.ensureOpen();
    final List<String> tableNames = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name")
        .map((row) => row.read<String>('name'))
        .get();

    expect(
      tableNames,
      containsAll(<String>['barcode_product_cache', 'categories', 'foods', 'locations']),
    );
  });

  test('初始版本为 1', () {
    expect(database.schemaVersion, 1);
  });

  test('食品表写入并读取完整字段', () async {
    await database.into(database.categories).insert(
      CategoriesCompanion.insert(
        id: 'category_dairy',
        name: '乳制品',
        isSystem: const Value<bool>(true),
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    await database.into(database.locations).insert(
      LocationsCompanion.insert(
        id: 'location_fridge',
        name: '冰箱冷藏',
        isSystem: const Value<bool>(true),
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    await database.into(database.foods).insert(
      FoodsCompanion.insert(
        id: 'food-1',
        barcode: const Value<String>('6901234567892'),
        name: '鲜牛奶',
        brand: const Value<String>('粮知牧场'),
        specification: const Value<String>('250ml'),
        imageLocalPath: const Value<String>('foods/milk.jpg'),
        imageRemoteUrl: const Value<String>('https://example.com/milk.jpg'),
        categoryId: const Value<String>('category_dairy'),
        locationId: const Value<String>('location_fridge'),
        quantity: 2.5,
        unit: const Value<String>('盒'),
        expiryInputType: 'production_shelf_life',
        productionDate: const Value<String>('2026-07-01'),
        shelfLifeValue: const Value<int>(30),
        shelfLifeUnit: const Value<String>('day'),
        expiryDate: '2026-07-31',
        reminderDaysBefore: const Value<int>(3),
        status: 'active',
        createdAt: 1,
        updatedAt: 2,
      ),
    );

    final Food saved = await database.select(database.foods).getSingle();
    expect(saved.name, '鲜牛奶');
    expect(saved.quantity, 2.5);
    expect(saved.categoryId, 'category_dairy');
    expect(saved.locationId, 'location_fridge');
    expect(saved.expiryDate, '2026-07-31');
    expect(saved.brand, '粮知牧场');

    await database.delete(database.foods).go();
    expect(await database.select(database.foods).get(), isEmpty);
  });

  test('食品表拒绝不一致到期字段', () async {
    final Future<int> insert = database.into(database.foods).insert(
      FoodsCompanion.insert(
        id: 'invalid-food',
        name: '无效食品',
        quantity: 1,
        expiryInputType: 'direct',
        productionDate: const Value<String>('2026-07-01'),
        expiryDate: '2026-07-31',
        status: 'active',
        createdAt: 1,
        updatedAt: 1,
      ),
    );

    await expectLater(insert, throwsA(isA<SqliteException>()));
  });

  test('分类表保存系统与用户分类并按顺序读取', () async {
    await database.batch((Batch batch) {
      batch.insertAll(database.categories, <CategoriesCompanion>[
        CategoriesCompanion.insert(
          id: 'category_user',
          name: '自定义',
          sortOrder: const Value<int>(20),
          createdAt: 2,
          updatedAt: 2,
        ),
        CategoriesCompanion.insert(
          id: 'category_system',
          name: '系统分类',
          sortOrder: const Value<int>(10),
          isSystem: const Value<bool>(true),
          createdAt: 1,
          updatedAt: 1,
        ),
      ]);
    });

    final List<Category> categories = await (database.select(
      database.categories,
    )..orderBy(<OrderClauseGenerator<$CategoriesTable>>[
      ($CategoriesTable table) => OrderingTerm.asc(table.sortOrder),
      ($CategoriesTable table) => OrderingTerm.asc(table.createdAt),
    ])).get();

    expect(categories.map((Category item) => item.id), <String>[
      'category_system',
      'category_user',
    ]);
    expect(categories.first.isSystem, isTrue);

    await expectLater(
      database.into(database.categories).insert(
        CategoriesCompanion.insert(
          id: 'category_system',
          name: '重复',
          createdAt: 3,
          updatedAt: 3,
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('空迁移入口不会丢失旧数据', () async {
    await database.close();
    final Directory temporaryDirectory = await Directory.systemTemp.createTemp('liangzhi_db_');
    final File databaseFile = File('${temporaryDirectory.path}/migration.sqlite');
    final AppDatabase versionOne = AppDatabase.forTesting(NativeDatabase(databaseFile));
    addTearDown(() async {
      await temporaryDirectory.delete(recursive: true);
    });

    await versionOne.into(versionOne.categories).insert(
      CategoriesCompanion.insert(
        id: 'category_test',
        name: '测试分类',
        createdAt: 1,
        updatedAt: 1,
        isSystem: const Value<bool>(false),
      ),
    );
    await versionOne.close();

    final _VersionTwoDatabase versionTwo = _VersionTwoDatabase(NativeDatabase(databaseFile));
    final Category saved = await (versionTwo.select(
      versionTwo.categories,
    )..where(($CategoriesTable table) => table.id.equals('category_test'))).getSingle();

    expect(saved.name, '测试分类');
    await versionTwo.close();
  });
}

class _VersionTwoDatabase extends AppDatabase {
  _VersionTwoDatabase(super.executor) : super.forTesting();

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator migrator, int from, int to) async {
      // This intentionally exercises the empty migration path.
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
