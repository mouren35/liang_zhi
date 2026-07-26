import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/providers/food_providers.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';

void main() {
  test('食品列表随 Repository 流自动更新', () async {
    final _StreamFoodRepository fake = _StreamFoodRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [foodRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(() async {
      container.dispose();
      await fake.close();
    });
    final ProviderSubscription<AsyncValue<List<Food>>> subscription = container.listen(
      foodListProvider,
      (AsyncValue<List<Food>>? previous, AsyncValue<List<Food>> next) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    fake.emit(<Food>[_food()]);
    final List<Food> foods = await container.read(foodListProvider.future);

    expect(foods.single.name, '苹果');
  });

  test('详情 Provider 处理成功、不存在和读取失败', () async {
    final _StreamFoodRepository fake = _StreamFoodRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [foodRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(() async {
      container.dispose();
      await fake.close();
    });

    Future<Food> readDetail(String id) {
      final provider = foodDetailProvider(id);
      final ProviderSubscription<AsyncValue<Food>> subscription = container.listen(
        provider,
        (AsyncValue<Food>? previous, AsyncValue<Food> next) {},
        fireImmediately: true,
      );
      return container.read(provider.future).whenComplete(subscription.close);
    }

    expect((await readDetail('food-1')).name, '苹果');

    fake.detailError = const DataNotFoundException();
    await expectLater(
      readDetail('missing'),
      throwsA(isA<DataNotFoundException>()),
    );

    fake.detailError = const DatabaseUnavailableException();
    await expectLater(
      readDetail('failed'),
      throwsA(isA<DatabaseUnavailableException>()),
    );
  });
}

final class _StreamFoodRepository implements FoodRepository {
  final StreamController<List<Food>> _controller = StreamController<List<Food>>.broadcast();
  Object? detailError;

  void emit(List<Food> foods) => _controller.add(foods);

  Future<void> close() => _controller.close();

  @override
  Future<void> add(Food food) async {}

  @override
  Future<List<Food>> getActiveFoods() async => <Food>[];

  @override
  Future<Food> getById(String id) async {
    if (detailError case final Object error) {
      throw error;
    }
    return _food();
  }

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {}

  @override
  Future<void> update(Food food) async {}

  @override
  Stream<List<Food>> watchActiveFoods() => _controller.stream;
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
