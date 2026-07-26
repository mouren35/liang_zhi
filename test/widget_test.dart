import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';

void main() {
  testWidgets('显示粮知占位首页', (WidgetTester tester) async {
    await tester.pumpWidget(
      LiangZhiApp(
        config: AppConfig(
          environment: AppEnvironment.production,
          openFoodFactsBaseUri: Uri.parse('https://example.com'),
        ),
      ),
    );

    expect(find.text('首页'), findsOneWidget);
  });
}
