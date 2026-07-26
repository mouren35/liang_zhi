import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/features/food_detail/food_detail_page.dart';
import 'package:liangzhi/shared/models/food.dart';

import '../../support/test_scope.dart';

void main() {
  testWidgets('详情显示食品信息和后续食谱说明', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodRepositoryProvider.overrideWithValue(_DetailRepository(_food()))],
        child: MaterialApp(
          home: FoodDetailPage(foodId: 'food-1', onBack: () {}, onEdit: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('苹果'), findsOneWidget);
    expect(find.text('2.0 份'), findsOneWidget);
    expect(find.text('2026-08-01'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('后续版本提供'), 240);
    expect(find.text('后续版本提供'), findsOneWidget);
  });

  testWidgets('不存在食品显示业务状态', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodRepositoryProvider.overrideWithValue(_DetailRepository(null)),
        ],
        child: MaterialApp(
          home: FoodDetailPage(foodId: 'missing', onBack: () {}, onEdit: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('食品不存在或已经删除'), findsOneWidget);
  });
}

final class _DetailRepository extends EmptyFoodRepository {
  _DetailRepository(this.food);

  final Food? food;

  @override
  Future<Food> getById(String id) async {
    return food ?? (throw const DataNotFoundException());
  }
}

Food _food() {
  return Food(
    id: 'food-1',
    name: '苹果',
    quantity: 2,
    unit: '份',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: DateTime(2026, 8),
    status: FoodStatus.active,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}
