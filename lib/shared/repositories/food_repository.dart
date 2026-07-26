import 'package:liangzhi/shared/models/food.dart';

abstract interface class FoodRepository {
  Future<List<Food>> getActiveFoods();

  Stream<List<Food>> watchActiveFoods();

  Future<Food> getById(String id);

  Future<void> add(Food food);

  Future<void> update(Food food);

  Future<void> softDelete(String id, {required DateTime deletedAt});
}
