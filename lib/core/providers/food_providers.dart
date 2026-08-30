import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/shared/models/food.dart';

final StreamProvider<List<Food>> foodListProvider = StreamProvider<List<Food>>(
  (Ref ref) => ref.watch(foodRepositoryProvider).watchActiveFoods(),
  name: 'foodListProvider',
  retry: (int retryCount, Object error) => null,
);

final foodDetailProvider = FutureProvider.family<Food, String>(
  (Ref ref, String id) => ref.watch(foodRepositoryProvider).getById(id),
  name: 'foodDetailProvider',
  retry: (int retryCount, Object error) => null,
);

final AsyncNotifierProvider<AddFoodController, void> addFoodControllerProvider =
    AsyncNotifierProvider<AddFoodController, void>(
      AddFoodController.new,
      name: 'addFoodControllerProvider',
      retry: (int retryCount, Object error) => null,
    );

final class AddFoodController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submit(Food food) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard<void>(() => ref.read(foodRepositoryProvider).add(food));
    if (state.hasError) {
      return false;
    }
    try {
      await ref.read(notificationCoordinatorProvider).afterFirstSuccessfulSave();
    } on Object {
      // 食品已成功保存时，通知权限或调度失败不得回滚业务数据。
    }
    return true;
  }

  void reset() {
    state = const AsyncData<void>(null);
  }
}
