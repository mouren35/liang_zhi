import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';

void main() {
  test('上层可只依赖 FoodRepository 接口与领域模型', () async {
    final Food food = _food();
    final FoodRepository repository = _FakeFoodRepository(<Food>[food]);

    final List<Food> foods = await repository.getActiveFoods();

    expect(foods.single, same(food));
  });
}

final class _FakeFoodRepository implements FoodRepository {
  _FakeFoodRepository(this.foods);

  final List<Food> foods;

  @override
  Future<void> add(Food food) async => foods.add(food);

  @override
  Future<Food> getById(String id) async => foods.singleWhere((Food food) => food.id == id);

  @override
  Future<List<Food>> getActiveFoods() async {
    return List<Food>.unmodifiable(foods.where((Food food) => food.isActive));
  }

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {
    final int index = foods.indexWhere((Food food) => food.id == id);
    foods[index] = foods[index].copyWith(deletedAt: deletedAt);
  }

  @override
  Future<void> update(Food food) async {
    final int index = foods.indexWhere((Food item) => item.id == food.id);
    foods[index] = food;
  }

  @override
  Stream<List<Food>> watchActiveFoods() => Stream<List<Food>>.value(
    List<Food>.unmodifiable(foods.where((Food food) => food.isActive)),
  );
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
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
