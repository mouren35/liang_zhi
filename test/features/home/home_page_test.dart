import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/time_providers.dart';
import 'package:liangzhi/features/home/home_page.dart';
import 'package:liangzhi/shared/models/food.dart';

import '../../support/test_scope.dart';

void main() {
  testWidgets('首页展示真实库存摘要并打开快速添加', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool addTapped = false;
    final _HomeFoodRepository repository = _HomeFoodRepository(<Food>[
      _food('fresh', DateTime(2026, 8, 20)),
      _food('soon', DateTime(2026, 7, 28)),
      _food('expired', DateTime(2026, 7, 20)),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodRepositoryProvider.overrideWithValue(repository),
          currentDateProvider.overrideWithValue(DateTime(2026, 7, 26)),
        ],
        child: MaterialApp(
          home: HomePage(
            onAddFood: () => addTapped = true,
            onOpenExpirations: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('库存概览'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    final Finder addButton = find.byKey(const ValueKey<String>('home-add-food'));
    await tester.scrollUntilVisible(addButton, 160);
    await tester.tap(addButton);
    expect(addTapped, isTrue);
  });
}

final class _HomeFoodRepository extends EmptyFoodRepository {
  _HomeFoodRepository(this.foods);

  final List<Food> foods;

  @override
  Stream<List<Food>> watchActiveFoods() => Stream<List<Food>>.value(foods);
}

Food _food(String id, DateTime expiryDate) {
  return Food(
    id: id,
    name: id,
    quantity: 1,
    unit: '份',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: expiryDate,
    status: FoodStatus.active,
    createdAt: DateTime.utc(2026, 7, 1),
    updatedAt: DateTime.utc(2026, 7, 1),
  );
}
