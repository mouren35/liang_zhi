import 'dart:math' as math;

import 'package:liangzhi/shared/models/food.dart';

DateTime calculateExpiryDate({
  required DateTime productionDate,
  required int shelfLifeValue,
  required ShelfLifeUnit shelfLifeUnit,
}) {
  if (shelfLifeValue <= 0) {
    throw const FormatException('保质期必须是正整数');
  }
  final DateTime date = dateOnly(productionDate);
  return switch (shelfLifeUnit) {
    ShelfLifeUnit.day => date.add(Duration(days: shelfLifeValue)),
    ShelfLifeUnit.month => _addMonths(date, shelfLifeValue),
    ShelfLifeUnit.year => _addYears(date, shelfLifeValue),
  };
}

DateTime _addMonths(DateTime date, int months) {
  final int zeroBasedMonth = date.month - 1 + months;
  final int year = date.year + zeroBasedMonth ~/ 12;
  final int month = zeroBasedMonth % 12 + 1;
  final int lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(date.day, lastDay));
}

DateTime _addYears(DateTime date, int years) {
  final int year = date.year + years;
  final int lastDay = DateTime(year, date.month + 1, 0).day;
  return DateTime(year, date.month, math.min(date.day, lastDay));
}
