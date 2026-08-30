import 'package:liangzhi/core/notifications/notification_models.dart';

abstract interface class NotificationPlatform {
  Future<void> initialize({
    required void Function(String payload) onNotificationTap,
  });

  Future<NotificationPermissionStatus> permissionStatus({
    required bool permissionRequested,
  });

  Future<NotificationPermissionStatus> requestPermission();

  Future<void> openSystemSettings();

  Future<void> replaceScheduled(
    List<LocalNotificationRequest> notifications,
  );

  Future<void> cancelAll();
}
