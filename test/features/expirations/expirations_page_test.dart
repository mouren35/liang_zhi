import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/time_providers.dart';
import 'package:liangzhi/features/expirations/expirations_page.dart';
import 'package:liangzhi/shared/models/food.dart';

import '../../support/test_scope.dart';

void main() {
  testWidgets('按临期、今日到期和已过期分组', (WidgetTester tester) async {
    final _ExpirationRepository repository = _ExpirationRepository(<Food>[
      _food('临期牛奶', DateTime(2026, 7, 28)),
      _food('今日面包', DateTime(2026, 7, 26)),
      _food('过期酸奶', DateTime(2026, 7, 25)),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodRepositoryProvider.overrideWithValue(repository),
          currentDateProvider.overrideWithValue(DateTime(2026, 7, 26)),
        ],
        child: MaterialApp(
          home: ExpirationsPage(onOpenSettings: () {}, onOpenFood: (String id) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('建议近期享用'), findsOneWidget);
    expect(find.textContaining('今天优先处理'), findsOneWidget);
    expect(find.textContaining('已超过记录日期'), findsOneWidget);
    expect(find.text('临期牛奶'), findsOneWidget);
    expect(find.text('今日面包'), findsOneWidget);
    expect(find.text('过期酸奶'), findsOneWidget);
  });

  testWidgets('空数据显示温和空状态', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [foodRepositoryProvider.overrideWithValue(const EmptyFoodRepository())],
        child: MaterialApp(
          home: ExpirationsPage(onOpenSettings: () {}, onOpenFood: (String id) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂时没有到期提醒'), findsOneWidget);
  });
}

final class _ExpirationRepository extends EmptyFoodRepository {
  _ExpirationRepository(this.foods);

  final List<Food> foods;

  @override
  Stream<List<Food>> watchActiveFoods() => Stream<List<Food>>.value(foods);
}

Food _food(String name, DateTime expiryDate) {
  return Food(
    id: name,
    name: name,
    quantity: 1,
    unit: '份',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: expiryDate,
    status: FoodStatus.active,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}
