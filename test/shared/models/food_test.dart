import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/models/food.dart';

void main() {
  group('Food', () {
    test('规范化字段并保留可选值', () {
      final Food food = Food(
        id: 'food-1',
        barcode: '6901234567892',
        name: '  鲜牛奶  ',
        brand: '品牌',
        specification: '250ml',
        imageRemoteUrl: Uri.parse('https://example.com/milk.jpg'),
        quantity: 1.25,
        unit: ' 盒 ',
        expiryInputType: ExpiryInputType.direct,
        expiryDate: DateTime(2026, 7, 31, 18),
        status: FoodStatus.active,
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 2),
      );

      expect(food.name, '鲜牛奶');
      expect(food.unit, '盒');
      expect(food.expiryDate, DateTime(2026, 7, 31));
      expect(food.brand, '品牌');
      expect(food.isActive, isTrue);
    });

    test('支持缺省品牌、规格和图片', () {
      final Food food = Food(
        id: 'food-2',
        name: '苹果',
        quantity: 1,
        unit: '份',
        expiryInputType: ExpiryInputType.direct,
        expiryDate: DateTime(2026, 8, 1),
        status: FoodStatus.active,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

      expect(food.brand, isNull);
      expect(food.specification, isNull);
      expect(food.imageRemoteUrl, isNull);
    });

    test('拒绝非法数量和不完整到期组合', () {
      expect(() => _food(quantity: 0), throwsFormatException);
      expect(() => _food(quantity: 1.0001), throwsFormatException);
      expect(
        () => _food(expiryInputType: ExpiryInputType.productionShelfLife),
        throwsFormatException,
      );
    });

    test('日期解析拒绝缺失或非法日期', () {
      expect(() => parseLocalDate(''), throwsFormatException);
      expect(() => parseLocalDate('2026-02-30'), throwsFormatException);
      expect(parseLocalDate('2024-02-29'), DateTime(2024, 2, 29));
    });
  });
}

Food _food({
  double quantity = 1,
  ExpiryInputType expiryInputType = ExpiryInputType.direct,
}) {
  return Food(
    id: 'food',
    name: '测试',
    quantity: quantity,
    unit: '份',
    expiryInputType: expiryInputType,
    expiryDate: DateTime(2026, 7, 31),
    status: FoodStatus.active,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
