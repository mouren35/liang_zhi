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
