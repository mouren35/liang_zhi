import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';

void main() {
  group('AppConfig', () {
    test('解析三种受支持环境', () {
      expect(AppEnvironment.parse('development'), AppEnvironment.development);
      expect(AppEnvironment.parse('test'), AppEnvironment.test);
      expect(AppEnvironment.parse('production'), AppEnvironment.production);
    });

    test('拒绝非 HTTPS 商品服务地址', () {
      expect(
        () => AppConfig(
          environment: AppEnvironment.test,
          openFoodFactsBaseUri: Uri.parse('http://example.com'),
        ),
        throwsArgumentError,
      );
    });

    testWidgets('开发环境显示标识而正式环境不显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        LiangZhiApp(
          config: AppConfig(
            environment: AppEnvironment.development,
            openFoodFactsBaseUri: Uri.parse('https://example.com'),
          ),
        ),
      );
      final Banner banner = tester.widget<Banner>(find.byType(Banner));
      expect(banner.message, '开发环境');

      await tester.pumpWidget(
        LiangZhiApp(
          config: AppConfig(
            environment: AppEnvironment.production,
            openFoodFactsBaseUri: Uri.parse('https://example.com'),
          ),
        ),
      );
      expect(find.byType(Banner), findsNothing);
    });
  });
}
