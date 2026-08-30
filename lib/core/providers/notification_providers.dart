import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/core/settings/settings_service.dart';

final FutureProvider<NotificationPermissionStatus> notificationPermissionStatusProvider =
    FutureProvider<NotificationPermissionStatus>(
      (Ref ref) => ref.watch(notificationCoordinatorProvider).permissionStatus(),
      name: 'notificationPermissionStatusProvider',
      retry: (int retryCount, Object error) => null,
    );

final AsyncNotifierProvider<NotificationSettingsController, AppSettings>
notificationSettingsControllerProvider =
    AsyncNotifierProvider<NotificationSettingsController, AppSettings>(
      NotificationSettingsController.new,
      name: 'notificationSettingsControllerProvider',
      retry: (int retryCount, Object error) => null,
    );

final class NotificationSettingsController extends AsyncNotifier<AppSettings> {
  @override
  FutureOr<AppSettings> build() {
    return ref.watch(settingsServiceProvider).read();
  }

  Future<void> setRemindersEnabled(bool value) =>
      _update((SettingsService service) => service.setRemindersEnabled(value));

  Future<void> setReminderTime(String value) =>
      _update((SettingsService service) => service.setReminderTime(value));

  Future<void> setGlobalReminderDaysOverride(int? value) => _update(
    (SettingsService service) => service.setGlobalReminderDaysOverride(value),
  );

  Future<void> setRemindExpired(bool value) =>
      _update((SettingsService service) => service.setRemindExpired(value));

  Future<void> setDailySummaryEnabled(bool value) => _update(
    (SettingsService service) => service.setDailySummaryEnabled(value),
  );

  Future<void> setLongTermReminderEnabled(bool value) => _update(
    (SettingsService service) => service.setLongTermReminderEnabled(value),
  );

  Future<void> setLongTermReminderDays(int value) => _update(
    (SettingsService service) => service.setLongTermReminderDays(value),
  );

  Future<void> openSystemSettings() async {
    await ref.read(notificationCoordinatorProvider).openSystemSettings();
  }

  Future<void> _update(
    Future<void> Function(SettingsService service) operation,
  ) async {
    if (state.isLoading) {
      return;
    }
    final SettingsService service = ref.read(settingsServiceProvider);
    state = const AsyncLoading<AppSettings>();
    state = await AsyncValue.guard<AppSettings>(() async {
      await operation(service);
      await ref.read(notificationCoordinatorProvider).reschedule();
      ref.invalidate(notificationPermissionStatusProvider);
      return service.read();
    });
  }
}
