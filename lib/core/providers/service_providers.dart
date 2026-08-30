import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/core/network/open_food_facts_product_lookup_repository.dart';
import 'package:liangzhi/core/notifications/flutter_notification_platform.dart';
import 'package:liangzhi/core/notifications/notification_coordinator.dart';
import 'package:liangzhi/core/notifications/notification_platform.dart';
import 'package:liangzhi/core/notifications/pending_notification_cleaner.dart';
import 'package:liangzhi/core/privacy/clear_local_data_service.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/repositories/cached_product_lookup_repository.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/core/storage/managed_food_image_store.dart';
import 'package:liangzhi/shared/repositories/product_lookup_repository.dart';

final Provider<http.Client> httpClientProvider = Provider<http.Client>(
  (Ref ref) {
    final http.Client client = http.Client();
    ref.onDispose(client.close);
    return client;
  },
  name: 'httpClientProvider',
);

final Provider<ProductLookupRepository> remoteProductLookupRepositoryProvider =
    Provider<ProductLookupRepository>(
      (Ref ref) => OpenFoodFactsProductLookupRepository(
        client: ref.watch(httpClientProvider),
        baseUri: AppConfig.current.openFoodFactsBaseUri,
      ),
      name: 'remoteProductLookupRepositoryProvider',
    );

final Provider<ProductLookupRepository> productLookupRepositoryProvider =
    Provider<ProductLookupRepository>(
      (Ref ref) => CachedProductLookupRepository(
        database: ref.watch(databaseProvider),
        remote: ref.watch(remoteProductLookupRepositoryProvider),
      ),
      name: 'productLookupRepositoryProvider',
    );

final Provider<SettingsService> settingsServiceProvider = Provider<SettingsService>(
  (Ref ref) => SettingsService.instance,
  name: 'settingsServiceProvider',
);

final Provider<NotificationPlatform> notificationPlatformProvider = Provider<NotificationPlatform>(
  (Ref ref) => FlutterNotificationPlatform.instance,
  name: 'notificationPlatformProvider',
);

final Provider<NotificationCoordinator> notificationCoordinatorProvider =
    Provider<NotificationCoordinator>(
      (Ref ref) => NotificationCoordinator(
        settings: ref.watch(settingsServiceProvider),
        foods: ref.watch(foodRepositoryProvider),
        platform: ref.watch(notificationPlatformProvider),
      ),
      name: 'notificationCoordinatorProvider',
    );

final Provider<PendingNotificationCleaner> pendingNotificationCleanerProvider =
    Provider<PendingNotificationCleaner>(
      (Ref ref) {
        final NotificationPlatform platform = ref.watch(
          notificationPlatformProvider,
        );
        if (platform is PendingNotificationCleaner) {
          return platform as PendingNotificationCleaner;
        }
        return FlutterPendingNotificationCleaner(
          FlutterLocalNotificationsPlugin(),
        );
      },
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
