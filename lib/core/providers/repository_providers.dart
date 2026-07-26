import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/repositories/local_food_repository.dart';
import 'package:liangzhi/core/repositories/local_reference_repositories.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';
import 'package:liangzhi/shared/repositories/reference_data_repository.dart';

final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>(
  (Ref ref) => AppDatabase.instance,
  name: 'databaseProvider',
);

final Provider<FoodRepository> foodRepositoryProvider = Provider<FoodRepository>(
  (Ref ref) => LocalFoodRepository(ref.watch(databaseProvider)),
  name: 'foodRepositoryProvider',
);

final Provider<CategoryRepository> categoryRepositoryProvider = Provider<CategoryRepository>(
  (Ref ref) => LocalCategoryRepository(ref.watch(databaseProvider)),
  name: 'categoryRepositoryProvider',
);

final Provider<LocationRepository> locationRepositoryProvider = Provider<LocationRepository>(
  (Ref ref) => LocalLocationRepository(ref.watch(databaseProvider)),
  name: 'locationRepositoryProvider',
);
