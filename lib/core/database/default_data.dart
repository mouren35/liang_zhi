import 'package:drift/drift.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';

const List<(String, String)> _defaultCategories = <(String, String)>[
  ('category_staple', '主食'),
  ('category_meat_poultry', '肉禽'),
  ('category_seafood', '水产'),
  ('category_vegetables', '蔬菜'),
  ('category_fruits', '水果'),
  ('category_dairy', '乳制品'),
  ('category_beverages', '饮料'),
  ('category_snacks', '零食'),
  ('category_condiments', '调味品'),
  ('category_frozen', '冷冻食品'),
  (DefaultIds.categoryOther, '其他'),
];

const List<(String, String)> _defaultLocations = <(String, String)>[
  ('location_fridge', '冰箱冷藏'),
  ('location_freezer', '冰箱冷冻'),
  ('location_kitchen_cabinet', '厨房橱柜'),
  ('location_snack_cabinet', '零食柜'),
  ('location_storage_room', '储物间'),
  (DefaultIds.locationOther, '其他'),
];

Future<void> initializeDefaultData(AppDatabase database, {DateTime? now}) async {
  final int timestamp = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
  await database.transaction(() async {
    for (final (int index, (String, String) item) in _defaultCategories.indexed) {
      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: item.$1,
              name: item.$2,
              sortOrder: Value<int>(index),
              isSystem: const Value<bool>(true),
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    for (final (int index, (String, String) item) in _defaultLocations.indexed) {
      await database
          .into(database.locations)
          .insert(
            LocationsCompanion.insert(
              id: item.$1,
              name: item.$2,
              sortOrder: Value<int>(index),
              isSystem: const Value<bool>(true),
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  });
}
