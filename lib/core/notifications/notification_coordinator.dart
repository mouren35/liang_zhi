import 'dart:async';

import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/notifications/notification_platform.dart';
import 'package:liangzhi/core/notifications/notification_rule_engine.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';

final class NotificationCoordinator {
  NotificationCoordinator({
    required SettingsService settings,
    required FoodRepository foods,
    required NotificationPlatform platform,
    DateTime Function()? now,
  }) : _settings = settings,
       _foods = foods,
       _platform = platform,
       _now = now ?? DateTime.now;

  final SettingsService _settings;
  final FoodRepository _foods;
  final NotificationPlatform _platform;
  final DateTime Function() _now;
  Future<void>? _rescheduleOperation;

  Future<NotificationPermissionStatus> permissionStatus() {
    final AppSettings settings = _settings.read();
    return _platform.permissionStatus(
      permissionRequested: settings.notificationPermissionRequested,
    );
  }

  Future<NotificationPermissionStatus> afterFirstSuccessfulSave() async {
    final AppSettings settings = _settings.read();
    NotificationPermissionStatus status = await _platform.permissionStatus(
      permissionRequested: settings.notificationPermissionRequested,
    );
    if (!settings.notificationPermissionRequested) {
      await _settings.setNotificationPermissionRequested(true);
      if (status != NotificationPermissionStatus.granted) {
        status = await _platform.requestPermission();
      }
    }
    unawaited(_rescheduleAfterSave());
    return status;
  }

  Future<void> openSystemSettings() => _platform.openSystemSettings();

  Future<void> reschedule() {
    return _rescheduleOperation ??= _performReschedule().whenComplete(
      () => _rescheduleOperation = null,
    );
  }

  Future<void> _performReschedule() async {
    final AppSettings settings = _settings.read();
    if (!settings.remindersEnabled) {
      await _platform.cancelAll();
      return;
    }
    final NotificationPermissionStatus status = await _platform.permissionStatus(
      permissionRequested: settings.notificationPermissionRequested,
    );
    if (status != NotificationPermissionStatus.granted) {
      await _platform.cancelAll();
      return;
    }
    final List<Food> foods = await _foods.getActiveFoods();
    final List<LocalNotificationRequest> schedule = NotificationRuleEngine.buildSchedule(
      foods: foods,
      settings: settings,
      now: _now(),
    );
    await _platform.replaceScheduled(schedule);
  }

  Future<void> _rescheduleAfterSave() async {
    try {
      await reschedule();
    } on Object {
      // 食品已经成功保存；通知平台失败不得延迟或回滚业务结果。
    }
  }
}
