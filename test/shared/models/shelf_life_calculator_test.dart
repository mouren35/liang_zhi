import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/shelf_life_calculator.dart';

void main() {
  test('按天相加', () {
    expect(
      calculateExpiryDate(
        productionDate: DateTime(2026, 7, 1),
        shelfLifeValue: 30,
        shelfLifeUnit: ShelfLifeUnit.day,
      ),
      DateTime(2026, 7, 31),
    );
  });

  test('月末没有同日时取目标月最后一天', () {
    expect(
      calculateExpiryDate(
        productionDate: DateTime(2026, 1, 31),
        shelfLifeValue: 1,
        shelfLifeUnit: ShelfLifeUnit.month,
      ),
      DateTime(2026, 2, 28),
    );
    expect(
      calculateExpiryDate(
        productionDate: DateTime(2024, 1, 31),
        shelfLifeValue: 1,
        shelfLifeUnit: ShelfLifeUnit.month,
      ),
      DateTime(2024, 2, 29),
    );
  });

  test('闰日按年相加取二月末', () {
    expect(
      calculateExpiryDate(
        productionDate: DateTime(2024, 2, 29),
        shelfLifeValue: 1,
        shelfLifeUnit: ShelfLifeUnit.year,
      ),
      DateTime(2025, 2, 28),
    );
  });
}
