import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';

Widget withTestScope(Widget child, {FoodRepository? foodRepository}) {
  return ProviderScope(
    overrides: [
      foodRepositoryProvider.overrideWithValue(foodRepository ?? const EmptyFoodRepository()),
    ],
    child: child,
  );
}

base class EmptyFoodRepository implements FoodRepository {
  const EmptyFoodRepository();

  @override
  Future<void> add(Food food) async {}

  @override
  Future<List<Food>> getActiveFoods() async => <Food>[];

  @override
  Future<Food> getById(String id) => throw const DataNotFoundException();

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {}

  @override
  Future<void> update(Food food) async {}

  @override
  Stream<List<Food>> watchActiveFoods() => Stream<List<Food>>.value(<Food>[]);
}
