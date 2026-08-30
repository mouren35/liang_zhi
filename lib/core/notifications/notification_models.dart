enum NotificationPermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
}

enum LocalNotificationKind { dailySummary, longTermInventory }

final class LocalNotificationRequest {
  const LocalNotificationRequest({
    required this.id,
    required this.kind,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final LocalNotificationKind kind;
  final DateTime scheduledAt;
  final String title;
  final String body;
  final String payload;
}

final class DailyExpirySummary {
  const DailyExpirySummary({
    required this.date,
    required this.expiring,
    required this.dueToday,
    required this.expired,
  });

  final DateTime date;
  final int expiring;
  final int dueToday;
  final int expired;

  int get total => expiring + dueToday + expired;
}
