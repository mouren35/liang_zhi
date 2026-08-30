import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/notifications/notification_coordinator.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/notifications/notification_platform.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('首次成功保存后只请求一次权限并建立调度', () async {
    final SettingsService settings = SettingsService.forTesting(
      await SharedPreferences.getInstance(),
    );
    final _FakeNotificationPlatform platform = _FakeNotificationPlatform(
      status: NotificationPermissionStatus.notDetermined,
      requestedStatus: NotificationPermissionStatus.granted,
    );
    final NotificationCoordinator coordinator = NotificationCoordinator(
      settings: settings,
      foods: _FoodRepository(<Food>[_food()]),
      platform: platform,
      now: () => DateTime(2026, 7, 1, 8),
    );

    expect(
      await coordinator.afterFirstSuccessfulSave(),
      NotificationPermissionStatus.granted,
    );
    await coordinator.reschedule();
    await coordinator.afterFirstSuccessfulSave();
    await coordinator.reschedule();

    expect(platform.requestCount, 1);
    expect(settings.read().notificationPermissionRequested, isTrue);
    expect(platform.replacements, 2);
    expect(platform.lastSchedule, isNotEmpty);
  });

  test('权限拒绝或总开关关闭时取消旧通知', () async {
    final SettingsService settings = SettingsService.forTesting(
      await SharedPreferences.getInstance(),
    );
    await settings.setNotificationPermissionRequested(true);
    final _FakeNotificationPlatform platform = _FakeNotificationPlatform(
      status: NotificationPermissionStatus.permanentlyDenied,
    );
    final NotificationCoordinator coordinator = NotificationCoordinator(
      settings: settings,
      foods: _FoodRepository(<Food>[_food()]),
      platform: platform,
    );

    await coordinator.reschedule();
    await settings.setRemindersEnabled(false);
    await coordinator.reschedule();

    expect(platform.cancelCount, 2);
    expect(platform.replacements, 0);
  });

  test('食品更新后重调度使用最新 updatedAt', () async {
    final SettingsService settings = SettingsService.forTesting(
      await SharedPreferences.getInstance(),
    );
    await settings.setNotificationPermissionRequested(true);
    final _FakeNotificationPlatform platform = _FakeNotificationPlatform(
      status: NotificationPermissionStatus.granted,
    );
    final _FoodRepository foods = _FoodRepository(<Food>[_food()]);
    final NotificationCoordinator coordinator = NotificationCoordinator(
      settings: settings,
      foods: foods,
      platform: platform,
      now: () => DateTime(2026, 7, 1, 8),
    );
    await coordinator.reschedule();
    final DateTime firstLongTerm = platform.lastSchedule
        .singleWhere(
          (LocalNotificationRequest item) => item.kind == LocalNotificationKind.longTermInventory,
        )
        .scheduledAt;

    foods.foods = <Food>[
      _food().copyWith(updatedAt: DateTime(2026, 7, 5)),
    ];
    await coordinator.reschedule();
    final DateTime updatedLongTerm = platform.lastSchedule
        .singleWhere(
          (LocalNotificationRequest item) => item.kind == LocalNotificationKind.longTermInventory,
        )
        .scheduledAt;

    expect(updatedLongTerm.isAfter(firstLongTerm), isTrue);
  });
}

final class _FakeNotificationPlatform implements NotificationPlatform {
  _FakeNotificationPlatform({
    required this.status,
    this.requestedStatus,
  });

  NotificationPermissionStatus status;
  final NotificationPermissionStatus? requestedStatus;
  int requestCount = 0;
  int cancelCount = 0;
  int replacements = 0;
  List<LocalNotificationRequest> lastSchedule = const <LocalNotificationRequest>[];

  @override
  Future<void> cancelAll() async {
    cancelCount += 1;
  }

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
  ) async {
    replacements += 1;
    lastSchedule = notifications;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestCount += 1;
    status = requestedStatus ?? status;
    return status;
  }
}

final class _FoodRepository extends EmptyFoodRepository {
  _FoodRepository(this.foods);

  List<Food> foods;

  @override
  Future<List<Food>> getActiveFoods() async => foods;
}

Food _food() {
  return Food(
    id: 'food',
    name: '牛奶',
    quantity: 1,
    unit: '盒',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: DateTime(2026, 7, 2),
    status: FoodStatus.active,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );
}
