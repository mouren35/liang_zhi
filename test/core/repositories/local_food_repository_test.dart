import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/database/app_database.dart' show AppDatabase;
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/core/repositories/local_food_repository.dart';
import 'package:liangzhi/shared/models/food.dart';

void main() {
  late AppDatabase database;
  late LocalFoodRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalFoodRepository(database);
  });

  tearDown(() => database.close());

  test('新增、查询、更新和软删除形成闭环', () async {
    final Food original = _food();
    await repository.add(original);
    expect((await repository.getActiveFoods()).single.name, '苹果');

    final Food updated = original.copyWith(
      name: '红苹果',
      quantity: 2,
      updatedAt: DateTime.utc(2026, 7, 2),
    );
    await repository.update(updated);
    expect((await repository.getById(original.id)).name, '红苹果');

    await repository.softDelete(original.id, deletedAt: DateTime.utc(2026, 7, 3));
    expect(await repository.getActiveFoods(), isEmpty);
    expect(await database.select(database.foods).get(), hasLength(1));
    await expectLater(repository.getById(original.id), throwsA(isA<DataNotFoundException>()));
  });

  test('监听流随新增自动更新', () async {
    final Stream<List<Food>> stream = repository.watchActiveFoods();
    expect(await stream.first, isEmpty);
    final Future<List<Food>> updated = stream.firstWhere((List<Food> foods) => foods.isNotEmpty);

    await repository.add(_food());

    expect((await updated).single.name, '苹果');
  });

  test('不存在食品返回统一异常', () async {
    await expectLater(repository.getById('missing'), throwsA(isA<DataNotFoundException>()));
  });

  test('底层写入失败转换为不含 SQL 的统一异常', () async {
    await repository.add(_food());

    try {
      await repository.add(_food());
      fail('重复 ID 应写入失败');
    } on DataWriteException catch (error) {
      expect(error.message, '保存失败，请稍后重试');
      expect(error.toString(), isNot(contains('UNIQUE')));
      expect(error.toString(), isNot(contains('INSERT')));
    }
  });
}

Food _food() {
  return Food(
    id: 'food-1',
    name: '苹果',
    quantity: 1,
    unit: '份',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: DateTime(2026, 8),
    status: FoodStatus.active,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}
