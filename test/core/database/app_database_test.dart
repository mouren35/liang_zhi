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
}
