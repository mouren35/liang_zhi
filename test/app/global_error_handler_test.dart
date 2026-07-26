import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/global_error_handler.dart';

void main() {
  testWidgets('正式环境错误组件不暴露技术细节', (WidgetTester tester) async {
    installGlobalErrorHandlers(
      AppConfig(
        environment: AppEnvironment.production,
        openFoodFactsBaseUri: Uri.parse('https://example.com'),
      ),
    );
    final Widget errorWidget = ErrorWidget.builder(
      FlutterErrorDetails(exception: StateError('sensitive stack detail')),
    );

    await tester.pumpWidget(MaterialApp(home: errorWidget));

    expect(find.text('页面暂时无法显示'), findsOneWidget);
    expect(find.textContaining('sensitive'), findsNothing);
  });

  testWidgets('开发环境错误组件只显示异常类型', (WidgetTester tester) async {
    installGlobalErrorHandlers(
      AppConfig(
        environment: AppEnvironment.development,
        openFoodFactsBaseUri: Uri.parse('https://example.com'),
      ),
    );
    final Widget errorWidget = ErrorWidget.builder(
      FlutterErrorDetails(exception: StateError('build failed')),
    );

    await tester.pumpWidget(MaterialApp(home: errorWidget));

    expect(find.textContaining('StateError'), findsOneWidget);
    expect(find.textContaining('build failed'), findsNothing);
  });
}
