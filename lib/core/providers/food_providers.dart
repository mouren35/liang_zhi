import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/shared/models/food.dart';

final StreamProvider<List<Food>> foodListProvider = StreamProvider<List<Food>>(
  (Ref ref) => ref.watch(foodRepositoryProvider).watchActiveFoods(),
  name: 'foodListProvider',
);

final foodDetailProvider = FutureProvider.family<Food, String>(
  (Ref ref, String id) => ref.watch(foodRepositoryProvider).getById(id),
  name: 'foodDetailProvider',
  retry: (int retryCount, Object error) => null,
);
