import 'package:liangzhi/shared/models/food.dart';

enum ExpiryStatus { fresh, expiring, dueToday, expired }

ExpiryStatus calculateExpiryStatus(
  Food food, {
  required DateTime today,
  int? globalReminderDaysOverride,
}) {
  final DateTime currentDate = dateOnly(today);
  final int remainingDays = food.expiryDate.difference(currentDate).inDays;
  if (remainingDays < 0) {
    return ExpiryStatus.expired;
  }
  if (remainingDays == 0) {
    return ExpiryStatus.dueToday;
  }
  final int reminderDays =
      food.reminderDaysBefore ??
      globalReminderDaysOverride ??
      defaultReminderDays(food);
  return remainingDays <= reminderDays ? ExpiryStatus.expiring : ExpiryStatus.fresh;
}

int defaultReminderDays(Food food) {
  final DateTime start = switch (food.expiryInputType) {
    ExpiryInputType.direct => dateOnly(food.createdAt.toLocal()),
    ExpiryInputType.productionShelfLife => food.productionDate!,
  };
  final int shelfDays = food.expiryDate.difference(start).inDays;
  if (shelfDays < 7) {
    return 1;
  }
  if (shelfDays <= 30) {
    return 3;
  }
  return 7;
}
