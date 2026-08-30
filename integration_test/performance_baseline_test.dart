import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/reference_item.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';
import 'package:liangzhi/shared/repositories/reference_data_repository.dart';

import 'support/granted_notification_platform.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('一百条食品的首屏、滚动、详情和流更新基线', (
    WidgetTester tester,
  ) async {
    final _PerformanceFoodRepository foods = _PerformanceFoodRepository(
      List<Food>.generate(100, (int index) => _food(index + 1)),
    );
    final Widget app = ProviderScope(
      overrides: [
        foodRepositoryProvider.overrideWithValue(foods),
        categoryRepositoryProvider.overrideWithValue(
          const _CategoryRepository(),
        ),
        locationRepositoryProvider.overrideWithValue(
          const _LocationRepository(),
        ),
        notificationPlatformProvider.overrideWithValue(
          const GrantedNotificationPlatform(),
        ),
      ],
      child: LiangZhiApp(
        config: AppConfig(
          environment: AppEnvironment.test,
          openFoodFactsBaseUri: Uri.parse('https://example.com'),
        ),
      ),
    );

    final Stopwatch homeWatch = Stopwatch()..start();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    homeWatch.stop();
    // ignore: avoid_print
    print('PERF_HOME_FIRST_RENDER_MS=${homeWatch.elapsedMilliseconds}');

    final Stopwatch listWatch = Stopwatch()..start();
    await tester.tap(find.text('全部食物').last);
    await tester.pumpAndSettle();
    listWatch.stop();
    // ignore: avoid_print
    print('PERF_100_ITEM_LIST_RENDER_MS=${listWatch.elapsedMilliseconds}');
    expect(find.text('测试食品 1'), findsOneWidget);

    final Stopwatch scrollWatch = Stopwatch()..start();
    await tester.scrollUntilVisible(
      find.text('测试食品 100'),
      600,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 30,
    );
    await tester.pumpAndSettle();
    scrollWatch.stop();
    // ignore: avoid_print
    print('PERF_100_ITEM_SCROLL_MS=${scrollWatch.elapsedMilliseconds}');

    await tester.tap(find.text('测试食品 100'));
    await tester.pumpAndSettle();
    expect(find.text('数量'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    final Stopwatch mutationWatch = Stopwatch()..start();
    await foods.add(_food(101));
    await tester.pumpAndSettle();
    await foods.softDelete('food-100', deletedAt: DateTime.now().toUtc());
    await tester.pumpAndSettle();
    mutationWatch.stop();
    // ignore: avoid_print
    print('PERF_ADD_DELETE_STREAM_MS=${mutationWatch.elapsedMilliseconds}');
    expect(foods.foods, hasLength(100));
    expect(foods.foods.any((Food food) => food.id == 'food-101'), isTrue);
    expect(foods.foods.any((Food food) => food.id == 'food-100'), isFalse);

    await foods.close();
  });
}

Food _food(int number) {
  return Food(
    id: 'food-$number',
    name: '测试食品 $number',
    categoryId: DefaultIds.categoryOther,
    locationId: DefaultIds.locationOther,
    quantity: 1,
    unit: '份',
    expiryInputType: ExpiryInputType.direct,
    expiryDate: DateTime(2026, 8, 1).add(Duration(days: number)),
    status: FoodStatus.active,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );
}

final class _PerformanceFoodRepository implements FoodRepository {
  _PerformanceFoodRepository(this.foods);

  final List<Food> foods;
  final StreamController<List<Food>> _changes = StreamController<List<Food>>.broadcast();

  Future<void> close() => _changes.close();

  void _emit() => _changes.add(List<Food>.unmodifiable(foods));

  @override
  Future<void> add(Food food) async {
    foods.add(food);
    _emit();
  }

  @override
  Future<List<Food>> getActiveFoods() async => List<Food>.unmodifiable(foods);

  @override
  Future<Food> getById(String id) async => foods.singleWhere((Food food) => food.id == id);

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {
    foods.removeWhere((Food food) => food.id == id);
    _emit();
  }

  @override
  Future<void> update(Food food) async {
    final int index = foods.indexWhere((Food item) => item.id == food.id);
    foods[index] = food;
    _emit();
  }

  @override
  Stream<List<Food>> watchActiveFoods() async* {
    yield List<Food>.unmodifiable(foods);
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
