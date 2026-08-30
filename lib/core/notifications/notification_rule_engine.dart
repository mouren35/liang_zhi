import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/shared/models/expiry_status.dart';
import 'package:liangzhi/shared/models/food.dart';

abstract final class NotificationRuleEngine {
  static const int rollingDays = 30;
  static const String expirationsPayload = '/expirations';

  static List<LocalNotificationRequest> buildSchedule({
    required List<Food> foods,
    required AppSettings settings,
    required DateTime now,
  }) {
    if (!settings.remindersEnabled) {
      return const <LocalNotificationRequest>[];
    }
    final List<Food> activeFoods = foods
        .where((Food food) => food.isActive)
        .toList(growable: false);
    final (int hour, int minute) = _parseTime(settings.reminderTime);
    final DateTime localNow = now.toLocal();
    final DateTime today = dateOnly(localNow);
    final List<LocalNotificationRequest> result = <LocalNotificationRequest>[];

    if (settings.dailySummaryEnabled) {
      for (int offset = 0; offset < rollingDays; offset += 1) {
        final DateTime date = today.add(Duration(days: offset));
        final DateTime scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        if (!scheduledAt.isAfter(localNow)) {
          continue;
        }
        final DailyExpirySummary summary = summarize(
          foods: activeFoods,
          date: date,
          globalReminderDaysOverride: settings.globalReminderDaysOverride,
          includeExpired: settings.remindExpired,
        );
        if (summary.total == 0) {
          continue;
        }
        result.add(
          LocalNotificationRequest(
            id: _dailyId(date),
            kind: LocalNotificationKind.dailySummary,
            scheduledAt: scheduledAt,
            title: '粮知到期提醒',
            body: _summaryBody(summary),
            payload: expirationsPayload,
          ),
        );
      }
    }

    if (settings.longTermReminderEnabled && activeFoods.isNotEmpty) {
      final DateTime latestUpdate = activeFoods
          .map((Food food) => food.updatedAt.toLocal())
          .reduce(
            (DateTime current, DateTime next) => next.isAfter(current) ? next : current,
          );
      final DateTime dueDate = dateOnly(
        latestUpdate,
      ).add(Duration(days: settings.longTermReminderDays));
      DateTime scheduledAt = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        hour,
        minute,
      );
      if (!scheduledAt.isAfter(localNow)) {
        final DateTime todayAtReminder = DateTime(
          today.year,
          today.month,
          today.day,
          hour,
          minute,
        );
        scheduledAt = todayAtReminder.isAfter(localNow)
            ? todayAtReminder
            : todayAtReminder.add(const Duration(days: 1));
      }
      result.add(
        LocalNotificationRequest(
          id: 900,
          kind: LocalNotificationKind.longTermInventory,
          scheduledAt: scheduledAt,
          title: '库存需要确认',
          body: '你的食品库存已有 ${settings.longTermReminderDays} 天未更新，请检查是否仍准确。',
          payload: expirationsPayload,
        ),
      );
    }

    result.sort(
      (LocalNotificationRequest first, LocalNotificationRequest second) =>
          first.scheduledAt.compareTo(second.scheduledAt),
    );
    return List<LocalNotificationRequest>.unmodifiable(result);
  }

  static DailyExpirySummary summarize({
    required List<Food> foods,
    required DateTime date,
    required int? globalReminderDaysOverride,
    required bool includeExpired,
  }) {
    int expiring = 0;
    int dueToday = 0;
    int expired = 0;
    final DateTime targetDate = dateOnly(date);
    for (final Food food in foods.where((Food food) => food.isActive)) {
      final int remaining = dateOnly(
        food.expiryDate,
      ).difference(targetDate).inDays;
      if (remaining < 0) {
        if (includeExpired) {
          expired += 1;
        }
        continue;
      }
      if (remaining == 0) {
        dueToday += 1;
        continue;
      }
      final int threshold =
          food.reminderDaysBefore ?? globalReminderDaysOverride ?? defaultReminderDays(food);
      if (remaining <= threshold) {
        expiring += 1;
      }
    }
    return DailyExpirySummary(
      date: targetDate,
      expiring: expiring,
      dueToday: dueToday,
      expired: expired,
    );
  }

  static (int, int) _parseTime(String value) {
    final List<String> parts = value.split(':');
    return (int.parse(parts.first), int.parse(parts.last));
  }

  static int _dailyId(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  static String _summaryBody(DailyExpirySummary summary) {
    final List<String> parts = <String>[];
    if (summary.expiring > 0) {
      parts.add('${summary.expiring} 件临期');
    }
    if (summary.dueToday > 0) {
      parts.add('${summary.dueToday} 件今日到期');
    }
    if (summary.expired > 0) {
      parts.add('${summary.expired} 件已过期');
    }
    return '${parts.join('，')}，请及时查看。';
  }
}
