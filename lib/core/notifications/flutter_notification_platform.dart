import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/notifications/notification_platform.dart';
import 'package:liangzhi/core/notifications/pending_notification_cleaner.dart';
import 'package:liangzhi/core/platform/system_settings_service.dart';
import 'package:timezone/timezone.dart' as timezone;

final class FlutterNotificationPlatform
    implements NotificationPlatform, PendingNotificationCleaner {
  FlutterNotificationPlatform._();

  static final FlutterNotificationPlatform instance = FlutterNotificationPlatform._();

  static const MethodChannel _permissionChannel = MethodChannel(
    'com.liangzhi.app/notification_permission',
  );
  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiry_reminders',
      '到期提醒',
      channelDescription: '食品临期、今日到期、已过期和长期未更新提醒',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> initialize({
    required void Function(String payload) onNotificationTap,
  }) async {
    if (!_isSupported || _initialized) {
      return;
    }
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          (
            NotificationResponse response,
          ) {
            final String? payload = response.payload;
            if (payload != null) {
              onNotificationTap(payload);
            }
          },
    );
    _initialized = true;
    final NotificationAppLaunchDetails? launchDetails = await _plugin
        .getNotificationAppLaunchDetails();
    final String? payload = launchDetails?.notificationResponse?.payload;
    if ((launchDetails?.didNotificationLaunchApp ?? false) && payload != null) {
      onNotificationTap(payload);
    }
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus({
    required bool permissionRequested,
  }) async {
    if (!_isSupported) {
      return NotificationPermissionStatus.granted;
    }
    try {
      final String? value = await _permissionChannel.invokeMethod<String>(
        'getPermissionStatus',
        <String, bool>{'requested': permissionRequested},
      );
      return _permissionStatusFromPlatform(value);
    } on MissingPluginException {
      return _fallbackPermissionStatus(permissionRequested);
    } on PlatformException {
      return _fallbackPermissionStatus(permissionRequested);
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!_isSupported) {
      return NotificationPermissionStatus.granted;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return permissionStatus(permissionRequested: true);
  }

  @override
  Future<void> openSystemSettings() => SystemSettingsService.openAppSettings();

  @override
  Future<void> replaceScheduled(
    List<LocalNotificationRequest> notifications,
  ) async {
    if (!_isSupported) {
      return;
    }
    await _refreshLocalTimezone();
    await _plugin.cancelAllPendingNotifications();
    for (final LocalNotificationRequest notification in notifications) {
      final DateTime value = notification.scheduledAt;
      final timezone.TZDateTime scheduledAt = timezone.TZDateTime(
        timezone.local,
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
      );
      await _plugin.zonedSchedule(
        id: notification.id,
        scheduledDate: scheduledAt,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: notification.title,
        body: notification.body,
        payload: notification.payload,
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _refreshLocalTimezone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(resolveTimezoneLocation(info.identifier));
    } on Object {
      throw const NotificationSchedulingException();
    }
  }

  Future<NotificationPermissionStatus> _fallbackPermissionStatus(
    bool permissionRequested,
  ) async {
    bool enabled = false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      enabled =
          await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    } else {
      enabled =
          (await _plugin
                  .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                  ?.checkPermissions())
              ?.isEnabled ??
          false;
    }
    if (enabled) {
      return NotificationPermissionStatus.granted;
    }
    return permissionRequested
        ? NotificationPermissionStatus.permanentlyDenied
        : NotificationPermissionStatus.notDetermined;
  }
}

@visibleForTesting
timezone.Location resolveTimezoneLocation(String identifier) {
  final String normalizedIdentifier = switch (identifier) {
    'GMT' || 'UTC' => 'Etc/UTC',
    _ => identifier,
  };
  return timezone.getLocation(normalizedIdentifier);
}

NotificationPermissionStatus _permissionStatusFromPlatform(String? value) {
  return switch (value) {
    'granted' => NotificationPermissionStatus.granted,
    'denied' => NotificationPermissionStatus.denied,
    'permanentlyDenied' => NotificationPermissionStatus.permanentlyDenied,
    _ => NotificationPermissionStatus.notDetermined,
  };
}
