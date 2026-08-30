import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/notifications/notification_rule_engine.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/shared/models/food.dart';

void main() {
  test('临期、今日、过期合并为每日一条且排除非有效食品', () {
    final DateTime now = DateTime(2026, 7, 1, 8);
    final List<Food> foods = <Food>[
      _food(id: 'expiring', expiry: DateTime(2026, 7, 2)),
      _food(id: 'today', expiry: DateTime(2026, 7, 1)),
      _food(id: 'expired', expiry: DateTime(2026, 6, 30)),
      _food(
        id: 'consumed',
        expiry: DateTime(2026, 7, 1),
        status: FoodStatus.consumed,
      ),
      _food(
        id: 'deleted',
        expiry: DateTime(2026, 7, 1),
        deletedAt: DateTime(2026, 6, 30),
      ),
    ];

    final List<LocalNotificationRequest> schedule = NotificationRuleEngine.buildSchedule(
      foods: foods,
      settings: _settings(longTermReminderEnabled: false),
      now: now,
    );
    final LocalNotificationRequest today = schedule.singleWhere(
      (LocalNotificationRequest item) => item.scheduledAt == DateTime(2026, 7, 1, 9),
    );

    expect(today.body, contains('1 件临期'));
    expect(today.body, contains('1 件今日到期'));
    expect(today.body, contains('1 件已过期'));
    expect(
      schedule
          .where(
            (LocalNotificationRequest item) => dateOnly(item.scheduledAt) == DateTime(2026, 7, 1),
          )
          .length,
      1,
    );
  });

  test('单品覆盖优先于全局覆盖且关闭过期提醒立即排除过期项', () {
    final DailyExpirySummary summary = NotificationRuleEngine.summarize(
      foods: <Food>[
        _food(
          id: 'item-override',
          expiry: DateTime(2026, 7, 6),
          reminderDaysBefore: 7,
        ),
        _food(id: 'global-override', expiry: DateTime(2026, 7, 4)),
        _food(id: 'fresh', expiry: DateTime(2026, 7, 8)),
        _food(id: 'expired', expiry: DateTime(2026, 6, 30)),
      ],
      date: DateTime(2026, 7, 1),
      globalReminderDaysOverride: 3,
      includeExpired: false,
    );

    expect(summary.expiring, 2);
    expect(summary.expired, 0);
  });

  test('09:00 已过则从次日滚动，最多 30 条汇总和 1 条长期提醒', () {
    final List<LocalNotificationRequest> schedule = NotificationRuleEngine.buildSchedule(
      foods: <Food>[
        _food(
          id: 'expired',
          expiry: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 5, 1),
        ),
      ],
      settings: _settings(),
      now: DateTime(2026, 7, 1, 10),
    );
    final List<LocalNotificationRequest> summaries = schedule
        .where(
          (LocalNotificationRequest item) => item.kind == LocalNotificationKind.dailySummary,
        )
        .toList(growable: false);

    expect(summaries, hasLength(29));
    expect(summaries.first.scheduledAt, DateTime(2026, 7, 2, 9));
    expect(schedule.length, lessThanOrEqualTo(31));
  });

  test('29、30、31 天长期未更新边界及空库存正确', () {
    for (final (int age, DateTime expected) in <(int, DateTime)>[
      (29, DateTime(2026, 8, 1, 9)),
      (30, DateTime(2026, 8, 1, 9)),
      (31, DateTime(2026, 8, 1, 9)),
    ]) {
      final List<LocalNotificationRequest> schedule = NotificationRuleEngine.buildSchedule(
        foods: <Food>[
          _food(
            id: 'food-$age',
            expiry: DateTime(2026, 8),
            updatedAt: DateTime(2026, 7, 31).subtract(
              Duration(days: age),
            ),
          ),
        ],
        settings: _settings(dailySummaryEnabled: false),
        now: DateTime(2026, 7, 31, 10),
      );
      expect(schedule.single.scheduledAt, expected);
    }

    expect(
      NotificationRuleEngine.buildSchedule(
        foods: const <Food>[],
        settings: _settings(dailySummaryEnabled: false),
        now: DateTime(2026, 7, 31, 10),
      ),
      isEmpty,
    );
  });

  test('关闭全部提醒返回空计划', () {
    expect(
      NotificationRuleEngine.buildSchedule(
        foods: <Food>[
          _food(id: 'food', expiry: DateTime(2026, 7, 1)),
        ],
        settings: _settings(remindersEnabled: false),
        now: DateTime(2026, 7, 1, 8),
      ),
      isEmpty,
    );
  });

  test('月末与本地午夜边界仍按日历日和当地 09:00 调度', () {
    final List<LocalNotificationRequest> schedule = NotificationRuleEngine.buildSchedule(
      foods: <Food>[
        _food(id: 'month-end', expiry: DateTime(2026, 2, 1)),
      ],
      settings: _settings(longTermReminderEnabled: false),
      now: DateTime(2026, 1, 31, 23, 30),
    );

    expect(schedule.first.scheduledAt, DateTime(2026, 2, 1, 9));
    expect(schedule.first.body, contains('今日到期'));
  });
}

AppSettings _settings({
  bool remindersEnabled = true,
  bool remindExpired = true,
  bool dailySummaryEnabled = true,
  bool longTermReminderEnabled = true,
}) {
  return AppSettings(
    hasCompletedInitialLaunch: false,
    foodListViewMode: FoodListViewMode.list,
    remindersEnabled: remindersEnabled,
    reminderTime: '09:00',
    globalReminderDaysOverride: null,
    remindExpired: remindExpired,
    dailySummaryEnabled: dailySummaryEnabled,
    longTermReminderEnabled: longTermReminderEnabled,
    longTermReminderDays: 30,
    notificationPermissionRequested: true,
  );
}

Food _food({
  required String id,
  required DateTime expiry,
  FoodStatus status = FoodStatus.active,
  DateTime? updatedAt,
  DateTime? deletedAt,
  int? reminderDaysBefore,
}) {
  return Food(
    id: id,
    name: id,
    quantity: 1,
    unit: '份',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: expiry,
    reminderDaysBefore: reminderDaysBefore,
    status: status,
    createdAt: DateTime(2026),
    updatedAt: updatedAt ?? DateTime(2026, 7, 1),
    deletedAt: deletedAt,
  );
}
