import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/notifications/pending_notification_cleaner.dart';
import 'package:liangzhi/core/privacy/clear_local_data_service.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/core/storage/managed_food_image_store.dart';

final Provider<SettingsService> settingsServiceProvider = Provider<SettingsService>(
  (Ref ref) => SettingsService.instance,
  name: 'settingsServiceProvider',
);

final Provider<PendingNotificationCleaner> pendingNotificationCleanerProvider =
    Provider<PendingNotificationCleaner>(
      (Ref ref) => FlutterPendingNotificationCleaner(FlutterLocalNotificationsPlugin()),
      name: 'pendingNotificationCleanerProvider',
    );

final Provider<ManagedFoodImageStore> managedFoodImageStoreProvider =
    Provider<ManagedFoodImageStore>(
      (Ref ref) => const ApplicationFoodImageStore(),
      name: 'managedFoodImageStoreProvider',
    );

final Provider<ClearLocalDataService> clearLocalDataServiceProvider =
    Provider<ClearLocalDataService>(
      (Ref ref) => ClearLocalDataService(
        database: ref.watch(databaseProvider),
        settings: ref.watch(settingsServiceProvider),
        notifications: ref.watch(pendingNotificationCleanerProvider),
        foodImages: ref.watch(managedFoodImageStoreProvider),
      ),
      name: 'clearLocalDataServiceProvider',
    );
