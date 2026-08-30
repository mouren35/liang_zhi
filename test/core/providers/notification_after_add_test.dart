import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/notifications/notification_platform.dart';
import 'package:liangzhi/core/providers/food_providers.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_scope.dart';

void main() {
  test('食品首次保存成功后申请一次通知权限，后续保存不重复申请', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsService settings = SettingsService.forTesting(
      await SharedPreferences.getInstance(),
    );
    final _PermissionPlatform platform = _PermissionPlatform();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        settingsServiceProvider.overrideWithValue(settings),
        foodRepositoryProvider.overrideWithValue(
          const EmptyFoodRepository(),
        ),
        notificationPlatformProvider.overrideWithValue(platform),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<AsyncValue<void>> subscription = container.listen(
      addFoodControllerProvider,
      (AsyncValue<void>? previous, AsyncValue<void> next) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(addFoodControllerProvider.future);
    final AddFoodController controller = container.read(
      addFoodControllerProvider.notifier,
    );

    expect(await controller.submit(_food('food-1')), isTrue);
    expect(await controller.submit(_food('food-2')), isTrue);

    expect(platform.requestCount, 1);
    expect(settings.read().notificationPermissionRequested, isTrue);
  });
}

final class _PermissionPlatform implements NotificationPlatform {
  NotificationPermissionStatus status = NotificationPermissionStatus.notDetermined;
  int requestCount = 0;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> initialize({
    required void Function(String payload) onNotificationTap,
  }) async {}

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<NotificationPermissionStatus> permissionStatus({
    required bool permissionRequested,
  }) async => status;

  @override
  Future<void> replaceScheduled(
    List<LocalNotificationRequest> notifications,
  ) async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestCount += 1;
    status = NotificationPermissionStatus.granted;
    return status;
  }
}

Food _food(String id) {
  return Food(
    id: id,
    name: '牛奶',
    quantity: 1,
    unit: '盒',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: DateTime(2026, 8),
    status: FoodStatus.active,
    createdAt: DateTime(2026, 7),
    updatedAt: DateTime(2026, 7),
  );
}
