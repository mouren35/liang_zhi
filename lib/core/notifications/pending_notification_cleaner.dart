import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract interface class PendingNotificationCleaner {
  Future<void> cancelAll();
}

final class FlutterPendingNotificationCleaner implements PendingNotificationCleaner {
  const FlutterPendingNotificationCleaner(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
