import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/time_providers.dart';
import 'package:liangzhi/features/foods/foods_page.dart';
import 'package:liangzhi/shared/models/food.dart';

import '../../support/test_scope.dart';

void main() {
  testWidgets('空库存显示添加入口', (WidgetTester tester) async {
    bool addTapped = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodRepositoryProvider.overrideWithValue(const EmptyFoodRepository())],
        child: MaterialApp(
          home: FoodsPage(onAddFood: () => addTapped = true, onOpenFood: (String id) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有食物'), findsOneWidget);
    await tester.tap(find.text('添加第一件食物'));
    expect(addTapped, isTrue);
  });

  testWidgets('列表显示名称、日期、数量并打开详情', (WidgetTester tester) async {
    String? openedId;
    final Food food = Food(
      id: 'food-1',
      name: '这是一个很长但仍然可以安全显示的测试食品名称',
      imageLocalPath: 'foods/example.jpg',
      quantity: 1.5,
      unit: '盒',
      expiryInputType: ExpiryInputType.direct,
      expiryDate: DateTime(2026, 7, 26),
      status: FoodStatus.active,
      createdAt: DateTime.utc(2026, 7),
      updatedAt: DateTime.utc(2026, 7),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodRepositoryProvider.overrideWithValue(_FoodsRepository(<Food>[food])),
          currentDateProvider.overrideWithValue(DateTime(2026, 7, 26)),
        ],
        child: MaterialApp(
          home: FoodsPage(onAddFood: () {}, onOpenFood: (String id) => openedId = id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('这是一个很长'), findsOneWidget);
    expect(find.text('到期 2026-07-26'), findsOneWidget);
    expect(find.text('1.5 盒'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey<String>('food-food-1')));
    expect(openedId, 'food-1');
  });
}

final class _FoodsRepository extends EmptyFoodRepository {
  _FoodsRepository(this.foods);

  final List<Food> foods;

  @override
  Stream<List<Food>> watchActiveFoods() => Stream<List<Food>>.value(foods);
}
