import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';

void main() {
  test('测试可替换 FoodRepository Provider', () {
    final _FakeFoodRepository fake = _FakeFoodRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [foodRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    expect(container.read(foodRepositoryProvider), same(fake));
  });
}

final class _FakeFoodRepository implements FoodRepository {
  @override
  Future<void> add(Food food) async {}

  @override
  Future<List<Food>> getActiveFoods() async => <Food>[];

  @override
  Future<Food> getById(String id) => throw UnimplementedError();

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {}

  @override
  Future<void> update(Food food) async {}

  @override
  Stream<List<Food>> watchActiveFoods() => const Stream<List<Food>>.empty();
}
