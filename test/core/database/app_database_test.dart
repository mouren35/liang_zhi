import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/database/barcode_cache_policy.dart';
import 'package:liangzhi/core/database/default_data.dart';

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

  test('存放位置表按顺序读取并拒绝重复 ID', () async {
    await database.batch((Batch batch) {
      batch.insertAll(database.locations, <LocationsCompanion>[
        LocationsCompanion.insert(
          id: 'location_cabinet',
          name: '厨房橱柜',
          sortOrder: const Value<int>(20),
          isSystem: const Value<bool>(true),
          createdAt: 2,
          updatedAt: 2,
        ),
        LocationsCompanion.insert(
          id: 'location_fridge',
          name: '冰箱冷藏',
          sortOrder: const Value<int>(10),
          isSystem: const Value<bool>(true),
          createdAt: 1,
          updatedAt: 1,
        ),
      ]);
    });

    final List<Location> locations = await (database.select(
      database.locations,
    )..orderBy(<OrderClauseGenerator<$LocationsTable>>[
      ($LocationsTable table) => OrderingTerm.asc(table.sortOrder),
      ($LocationsTable table) => OrderingTerm.asc(table.createdAt),
    ])).get();

    expect(locations.map((Location item) => item.name), <String>['冰箱冷藏', '厨房橱柜']);

    await expectLater(
      database.into(database.locations).insert(
        LocationsCompanion.insert(
          id: 'location_fridge',
          name: '重复',
          createdAt: 3,
          updatedAt: 3,
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('食品表只建立计划所需索引', () async {
    final List<String> indexNames = await database
        .customSelect("PRAGMA index_list('foods')")
        .map((QueryRow row) => row.read<String>('name'))
        .get();

    expect(
      indexNames,
      containsAll(<String>[
        'idx_foods_active_expiry',
        'idx_foods_updated_at',
        'idx_foods_category_id',
        'idx_foods_location_id',
        'idx_foods_barcode',
      ]),
    );
  });

  test('默认分类与位置初始化幂等且包含稳定其他项', () async {
    final DateTime fixedTime = DateTime.utc(2026, 7, 26);
    await initializeDefaultData(database, now: fixedTime);
    await initializeDefaultData(database, now: fixedTime);

    final List<Category> categories = await database.select(database.categories).get();
    final List<Location> locations = await database.select(database.locations).get();

    expect(categories, hasLength(11));
    expect(locations, hasLength(6));
    expect(
      categories.singleWhere((Category item) => item.id == DefaultIds.categoryOther).name,
      '其他',
    );
    expect(
      locations.singleWhere((Location item) => item.id == DefaultIds.locationOther).name,
      '其他',
    );
    expect(categories.every((Category item) => item.isSystem), isTrue);
  });

  test('每个数据库测试从空业务数据开始', () async {
    expect(await database.select(database.foods).get(), isEmpty);
    expect(await database.select(database.barcodeProductCache).get(), isEmpty);
  });

  test('条码缓存命中 30 天、未命中 24 小时过期', () async {
    final DateTime fetchedAt = DateTime.utc(2026, 7, 1, 9);
    final DateTime foundExpiry = BarcodeCachePolicy.expiresAt(
      lookupStatus: 'found',
      fetchedAt: fetchedAt,
    );
    final DateTime notFoundExpiry = BarcodeCachePolicy.expiresAt(
      lookupStatus: 'not_found',
      fetchedAt: fetchedAt,
    );

    expect(foundExpiry, DateTime.utc(2026, 7, 31, 9));
    expect(notFoundExpiry, DateTime.utc(2026, 7, 2, 9));

    await database.into(database.barcodeProductCache).insert(
      BarcodeProductCacheCompanion.insert(
        barcode: '6901234567892',
        lookupStatus: 'found',
        productName: const Value<String>('测试商品'),
        fetchedAt: fetchedAt.millisecondsSinceEpoch,
        expiresAt: foundExpiry.millisecondsSinceEpoch,
      ),
    );
    final BarcodeProductCacheData saved = await database
        .select(database.barcodeProductCache)
        .getSingle();
    expect(saved.productName, '测试商品');
    expect(
      BarcodeCachePolicy.isExpired(
        expiresAtUtcMillis: saved.expiresAt,
        now: foundExpiry,
      ),
      isTrue,
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
