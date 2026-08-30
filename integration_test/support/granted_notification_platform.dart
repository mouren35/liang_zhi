import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/notifications/notification_platform.dart';

/// 集成业务流程使用的无副作用通知平台。
///
/// 通知权限和系统调度由独立的平台验收覆盖；业务集成用例不应被系统弹窗
/// 抢走焦点，也不应在设备上留下真实通知。
final class GrantedNotificationPlatform implements NotificationPlatform {
  const GrantedNotificationPlatform();

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
  }) async => NotificationPermissionStatus.granted;

  @override
  Future<void> replaceScheduled(
    List<LocalNotificationRequest> notifications,
  ) async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.granted;
}
