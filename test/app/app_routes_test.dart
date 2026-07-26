import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/app_routes.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';
import 'package:liangzhi/features/foods/foods_page.dart';

void main() {
  testWidgets('集中定义的所有页面路由均可直接打开', (WidgetTester tester) async {
    final GoRouter router = createAppRouter();
    await tester.pumpWidget(
      LiangZhiApp(
        router: router,
        config: AppConfig(
          environment: AppEnvironment.production,
          openFoodFactsBaseUri: Uri.parse('https://example.com'),
        ),
      ),
    );

    for (final (String path, String label) in <(String, String)>[
      (AppRoutes.home, '首页'),
      (AppRoutes.expirations, '到期提醒'),
      (AppRoutes.scan, '扫码添加'),
      (AppRoutes.foods, '全部食物'),
      (AppRoutes.addFood, '手动添加食物'),
      (AppRoutes.foodDetail('food-1'), '食物详情：food-1'),
      (AppRoutes.mine, '我的'),
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets, reason: path);
    }
  });

  testWidgets('底部导航切换分支并保持可见', (WidgetTester tester) async {
    final GoRouter router = createAppRouter();
    await tester.pumpWidget(
      LiangZhiApp(
        router: router,
        config: AppConfig(
          environment: AppEnvironment.production,
          openFoodFactsBaseUri: Uri.parse('https://example.com'),
        ),
      ),
    );

    await tester.tap(find.text('全部食物').last);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.foods);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('全部食物'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
  });

  testWidgets('一级分支切换时保留原页面元素', (WidgetTester tester) async {
    final GoRouter router = createAppRouter(initialLocation: AppRoutes.foods);
    await tester.pumpWidget(
      LiangZhiApp(
        router: router,
        config: AppConfig(
          environment: AppEnvironment.production,
          openFoodFactsBaseUri: Uri.parse('https://example.com'),
        ),
      ),
    );
    final Element originalFoodsElement = find.byType(FoodsPage).evaluate().single;

    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    router.go(AppRoutes.foods);
    await tester.pumpAndSettle();

    expect(find.byType(FoodsPage).evaluate().single, same(originalFoodsElement));
  });

  testWidgets('详情返回恢复全部食物分支与原页面', (WidgetTester tester) async {
    final GoRouter router = createAppRouter(initialLocation: AppRoutes.foods);
    await tester.pumpWidget(
      LiangZhiApp(
        router: router,
        config: AppConfig(
          environment: AppEnvironment.production,
          openFoodFactsBaseUri: Uri.parse('https://example.com'),
        ),
      ),
    );
    final Element originalFoodsElement = find.byType(FoodsPage).evaluate().single;

    router.push(AppRoutes.foodDetail('food-1'));
    await tester.pumpAndSettle();
    expect(find.text('食物详情：food-1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.foods);
    expect(find.byType(FoodsPage).evaluate().single, same(originalFoodsElement));
  });
}
