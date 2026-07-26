import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/models/expiry_status.dart';
import 'package:liangzhi/shared/models/food.dart';

void main() {
  test('区分新鲜、临期、今日和过期', () {
    final DateTime today = DateTime(2026, 7, 26);
    expect(calculateExpiryStatus(_food(DateTime(2026, 8, 20)), today: today), ExpiryStatus.fresh);
    expect(
      calculateExpiryStatus(_food(DateTime(2026, 7, 28)), today: today),
      ExpiryStatus.expiring,
    );
    expect(
      calculateExpiryStatus(_food(DateTime(2026, 7, 26)), today: today),
      ExpiryStatus.dueToday,
    );
    expect(
      calculateExpiryStatus(_food(DateTime(2026, 7, 25)), today: today),
      ExpiryStatus.expired,
    );
  });

  test('不足 7、7—30 和超过 30 天采用 1/3/7 天阈值', () {
    expect(defaultReminderDays(_food(DateTime(2026, 7, 6), createdAt: DateTime.utc(2026, 7))), 1);
    expect(defaultReminderDays(_food(DateTime(2026, 7, 20), createdAt: DateTime.utc(2026, 7))), 3);
    expect(defaultReminderDays(_food(DateTime(2026, 8, 15), createdAt: DateTime.utc(2026, 7))), 7);
  });

  test('单品和全局覆盖优先级正确', () {
    final Food food = _food(DateTime(2026, 8, 5), reminderDaysBefore: 10);
    expect(
      calculateExpiryStatus(food, today: DateTime(2026, 7, 26), globalReminderDaysOverride: 2),
      ExpiryStatus.expiring,
    );
  });
}

Food _food(
  DateTime expiryDate, {
  DateTime? createdAt,
  int? reminderDaysBefore,
}) {
  return Food(
    id: expiryDate.toIso8601String(),
    name: '测试',
    quantity: 1,
    unit: '份',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: expiryDate,
    reminderDaysBefore: reminderDaysBefore,
    status: FoodStatus.active,
    createdAt: createdAt ?? DateTime.utc(2026, 7, 1),
    updatedAt: DateTime.utc(2026, 7, 1),
  );
}
