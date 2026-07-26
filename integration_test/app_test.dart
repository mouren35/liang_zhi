import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/reference_item.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';
import 'package:liangzhi/shared/repositories/reference_data_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('手动添加、查看详情并在应用重建后保留', (WidgetTester tester) async {
    final _PersistentFakeFoodRepository foods = _PersistentFakeFoodRepository();
    final Widget app = ProviderScope(
      overrides: [
        foodRepositoryProvider.overrideWithValue(foods),
        categoryRepositoryProvider.overrideWithValue(const _CategoryRepository()),
        locationRepositoryProvider.overrideWithValue(const _LocationRepository()),
      ],
      child: LiangZhiApp(
        config: AppConfig(
          environment: AppEnvironment.test,
          openFoodFactsBaseUri: Uri.parse('https://example.com'),
        ),
      ),
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部食物').last);
    await tester.pumpAndSettle();
    expect(find.text('还没有食物'), findsOneWidget);

    await tester.tap(find.text('添加第一件食物'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey<String>('food-name')), '测试苹果');
    final Element expiryElement = find.byKey(const ValueKey<String>('expiry-date')).evaluate().last;
    final Finder expiryDate = find.byElementPredicate(
      (Element element) => identical(element, expiryElement),
    );
    await tester.ensureVisible(expiryDate);
    await tester.tap(expiryDate);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final Element formListElement = find.byType(ListView).evaluate().last;
    final Finder formList = find.byElementPredicate(
      (Element element) => identical(element, formListElement),
    );
    await tester.drag(formList, const Offset(0, -600));
    await tester.pumpAndSettle();
    final Element saveElement = find.byKey(const ValueKey<String>('save-food')).evaluate().last;
    final Finder saveFood = find.byElementPredicate(
      (Element element) => identical(element, saveElement),
    );
    await tester.ensureVisible(saveFood);
    await tester.tap(saveFood);
    await tester.pumpAndSettle();

    expect(find.text('测试苹果'), findsOneWidget);
    await tester.tap(find.text('测试苹果'));
    await tester.pumpAndSettle();
    expect(find.text('后续版本提供'), findsNothing);
    expect(find.text('数量'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部食物').last);
    await tester.pumpAndSettle();
    expect(find.text('测试苹果'), findsOneWidget);
    await foods.close();
  });
}

final class _PersistentFakeFoodRepository implements FoodRepository {
  final List<Food> _foods = <Food>[];
  final StreamController<List<Food>> _changes = StreamController<List<Food>>.broadcast();

  Future<void> close() => _changes.close();

  void _emit() => _changes.add(List<Food>.unmodifiable(_foods));

  @override
  Future<void> add(Food food) async {
    _foods.add(food);
    _emit();
  }

  @override
  Future<List<Food>> getActiveFoods() async => List<Food>.unmodifiable(_foods);

  @override
  Future<Food> getById(String id) async => _foods.singleWhere((Food food) => food.id == id);

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {}

  @override
  Future<void> update(Food food) async {}

  @override
  Stream<List<Food>> watchActiveFoods() async* {
    yield List<Food>.unmodifiable(_foods);
    yield* _changes.stream;
  }
}

final class _CategoryRepository implements CategoryRepository {
  const _CategoryRepository();

  static const ReferenceItem other = ReferenceItem(
    id: DefaultIds.categoryOther,
    name: '其他',
    isSystem: true,
  );

  @override
  Future<List<ReferenceItem>> getAll() async => const <ReferenceItem>[other];

  @override
  Future<ReferenceItem?> getDefault() async => other;
}

final class _LocationRepository implements LocationRepository {
  const _LocationRepository();

  static const ReferenceItem other = ReferenceItem(
    id: DefaultIds.locationOther,
    name: '其他',
    isSystem: true,
  );

  @override
  Future<List<ReferenceItem>> getAll() async => const <ReferenceItem>[other];

  @override
  Future<ReferenceItem?> getDefault() async => other;
}
