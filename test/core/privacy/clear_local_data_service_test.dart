import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/database/default_data.dart';
import 'package:liangzhi/core/notifications/pending_notification_cleaner.dart';
import 'package:liangzhi/core/privacy/clear_local_data_service.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/core/storage/managed_food_image_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late SettingsService settings;
  late _FakeNotificationCleaner notifications;
  late _FakeFoodImageStore images;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsService.forTesting(await SharedPreferences.getInstance());
    notifications = _FakeNotificationCleaner();
    images = _FakeFoodImageStore();
    await initializeDefaultData(database, now: DateTime.utc(2026));
  });

  tearDown(() => database.close());

  test('清除全部业务数据并恢复系统默认项与设置', () async {
    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'user-category',
            name: '自定义分类',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await database
        .into(database.locations)
        .insert(
          LocationsCompanion.insert(
            id: 'user-location',
            name: '自定义位置',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await database
        .into(database.foods)
        .insert(
          FoodsCompanion.insert(
            id: 'food-1',
            name: '苹果',
            categoryId: const Value<String>('user-category'),
            locationId: const Value<String>('user-location'),
            quantity: 2,
            expiryInputType: 'direct',
            expiryDate: '2026-08-01',
            status: 'active',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await database
        .into(database.barcodeProductCache)
        .insert(
          BarcodeProductCacheCompanion.insert(
            barcode: '6901234567892',
            lookupStatus: 'not_found',
            fetchedAt: 1,
            expiresAt: 2,
          ),
        );
    await settings.setHasCompletedInitialLaunch(true);
    await settings.setRemindersEnabled(false);

    await ClearLocalDataService(
      database: database,
      settings: settings,
      notifications: notifications,
      foodImages: images,
    ).clear();

    expect(await database.select(database.foods).get(), isEmpty);
    expect(await database.select(database.barcodeProductCache).get(), isEmpty);
    expect(
      await database.select(database.categories).get(),
      everyElement(
        isA<Category>().having(
          (Category item) => item.isSystem,
          'isSystem',
          isTrue,
        ),
      ),
    );
    expect(
      await database.select(database.locations).get(),
      everyElement(
        isA<Location>().having(
          (Location item) => item.isSystem,
          'isSystem',
          isTrue,
        ),
      ),
    );
    expect(settings.read().hasCompletedInitialLaunch, isFalse);
    expect(settings.read().remindersEnabled, isTrue);
    expect(notifications.calls, 1);
    expect(images.calls, 1);
  });

  test('托管图片清理不删除应用支持根目录', () async {
    final Directory root = await Directory.systemTemp.createTemp(
      'liangzhi-images-',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    final ApplicationFoodImageStore store = ApplicationFoodImageStore(
      applicationSupportDirectory: () async => root,
    );
    final Directory managed = await store.directory();
    await managed.create(recursive: true);
    await File(
      '${managed.path}${Platform.pathSeparator}food.jpg',
    ).writeAsString('image');

    await store.clear();

    expect(await managed.exists(), isFalse);
    expect(await root.exists(), isTrue);
  });
}

final class _FakeNotificationCleaner implements PendingNotificationCleaner {
  int calls = 0;

  @override
  Future<void> cancelAll() async {
    calls += 1;
  }
}

final class _FakeFoodImageStore implements ManagedFoodImageStore {
  int calls = 0;

  @override
  Future<void> clear() async {
    calls += 1;
  }
}
