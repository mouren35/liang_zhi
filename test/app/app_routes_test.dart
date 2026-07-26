import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/app_routes.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';

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
      expect(find.text(label), findsOneWidget, reason: path);
    }
  });
}
