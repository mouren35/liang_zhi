import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';

import '../support/test_scope.dart';

void main() {
  testWidgets('底部导航触控区域与语义标签可用', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      withTestScope(
        LiangZhiApp(
          config: AppConfig(
            environment: AppEnvironment.production,
            openFoodFactsBaseUri: Uri.parse('https://example.com'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('首页')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('到期提醒')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('扫码添加')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('全部食物')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('我的')), findsWidgets);
    for (final Element element in find.byType(NavigationDestination).evaluate()) {
      final Size size = tester.getSize(find.byWidget(element.widget));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
    semantics.dispose();
  });

  testWidgets('200% 文本缩放和常见小屏尺寸无布局异常', (WidgetTester tester) async {
    for (final Size size in <Size>[
      const Size(320, 568),
      const Size(360, 640),
      const Size(375, 667),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size, textScaler: const TextScaler.linear(2)),
          child: withTestScope(
            LiangZhiApp(
              config: AppConfig(
                environment: AppEnvironment.production,
                openFoodFactsBaseUri: Uri.parse('https://example.com'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
