import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/database/default_data.dart';
import 'package:liangzhi/core/repositories/local_reference_repositories.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('默认分类和位置按顺序读取并使用稳定其他项', () async {
    await initializeDefaultData(database, now: DateTime.utc(2026));
    final LocalCategoryRepository categories = LocalCategoryRepository(database);
    final LocalLocationRepository locations = LocalLocationRepository(database);

    expect((await categories.getAll()).first.name, '主食');
    expect((await locations.getAll()).first.name, '冰箱冷藏');
    expect((await categories.getDefault())?.id, DefaultIds.categoryOther);
    expect((await locations.getDefault())?.id, DefaultIds.locationOther);
  });

  test('空表返回空列表和空默认值而不崩溃', () async {
    final LocalCategoryRepository categories = LocalCategoryRepository(database);
    final LocalLocationRepository locations = LocalLocationRepository(database);

    expect(await categories.getAll(), isEmpty);
    expect(await locations.getAll(), isEmpty);
    expect(await categories.getDefault(), isNull);
    expect(await locations.getDefault(), isNull);
  });
}
