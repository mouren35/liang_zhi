import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/database/default_data.dart';
import 'package:liangzhi/core/notifications/pending_notification_cleaner.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/core/storage/managed_food_image_store.dart';

final class ClearLocalDataService {
  const ClearLocalDataService({
    required AppDatabase database,
    required SettingsService settings,
    required PendingNotificationCleaner notifications,
    required ManagedFoodImageStore foodImages,
  }) : _database = database,
       _settings = settings,
       _notifications = notifications,
       _foodImages = foodImages;

  final AppDatabase _database;
  final SettingsService _settings;
  final PendingNotificationCleaner _notifications;
  final ManagedFoodImageStore _foodImages;

  Future<void> clear() async {
    await _notifications.cancelAll();
    await _database.transaction(() async {
      await _database.delete(_database.foods).go();
      await _database.delete(_database.barcodeProductCache).go();
      await (_database.delete(
        _database.categories,
      )..where((Categories table) => table.isSystem.equals(false))).go();
      await (_database.delete(
        _database.locations,
      )..where((Locations table) => table.isSystem.equals(false))).go();
    });
    await _foodImages.clear();
    await _settings.clear();
    await initializeDefaultData(_database);
    await _settings.setHasCompletedInitialLaunch(false);
  }
}
