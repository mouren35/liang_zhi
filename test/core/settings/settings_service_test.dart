import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('使用架构默认值且可持久化全部基础设置', () async {
    final SettingsService service = SettingsService.forTesting(
      await SharedPreferences.getInstance(),
    );
    final AppSettings defaults = service.read();
    expect(defaults.hasCompletedInitialLaunch, isFalse);
    expect(defaults.foodListViewMode, FoodListViewMode.list);
    expect(defaults.remindersEnabled, isTrue);
    expect(defaults.reminderTime, '09:00');
    expect(defaults.globalReminderDaysOverride, isNull);
    expect(defaults.remindExpired, isTrue);
    expect(defaults.dailySummaryEnabled, isTrue);
    expect(defaults.longTermReminderEnabled, isTrue);
    expect(defaults.longTermReminderDays, 30);
    expect(defaults.notificationPermissionRequested, isFalse);

    await service.setHasCompletedInitialLaunch(true);
    await service.setReminderTime('08:30');
    await service.setGlobalReminderDaysOverride(5);
    await service.setLongTermReminderDays(45);
    await service.setNotificationPermissionRequested(true);
    final AppSettings saved = service.read();
    expect(saved.hasCompletedInitialLaunch, isTrue);
    expect(saved.reminderTime, '08:30');
    expect(saved.globalReminderDaysOverride, 5);
    expect(saved.longTermReminderDays, 45);
    expect(saved.notificationPermissionRequested, isTrue);
  });

  test('未知界面偏好和非法设置回退安全默认值', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SettingsKeys.foodListViewMode: 'grid',
      SettingsKeys.reminderTime: '99:99',
      SettingsKeys.longTermReminderDays: -1,
    });
    final SettingsService service = SettingsService.forTesting(
      await SharedPreferences.getInstance(),
    );

    expect(service.read().foodListViewMode, FoodListViewMode.list);
    expect(service.read().reminderTime, '09:00');
    expect(service.read().longTermReminderDays, 30);
    expect(() => service.setReminderTime('25:00'), throwsFormatException);
    await expectLater(service.setGlobalReminderDaysOverride(-1), throwsFormatException);
  });

  test('清除后首次启动和设置恢复默认', () async {
    final SettingsService service = SettingsService.forTesting(
      await SharedPreferences.getInstance(),
    );
    await service.setHasCompletedInitialLaunch(true);
    await service.setFoodListViewMode(FoodListViewMode.list);
    await service.setRemindersEnabled(false);
    await service.setNotificationPermissionRequested(true);

    await service.clear();

    expect(service.read().hasCompletedInitialLaunch, isFalse);
    expect(service.read().remindersEnabled, isTrue);
    expect(service.read().notificationPermissionRequested, isFalse);
  });
}
