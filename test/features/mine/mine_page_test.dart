import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/features/mine/mine_page.dart';

void main() {
  testWidgets('显示版本、隐私和 Open Food Facts 来源', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: _page(onClearData: () async {})));

    expect(find.text('版本 0.1.0（1）'), findsOneWidget);
    expect(find.text('Open Food Facts'), findsOneWidget);
    expect(find.text('隐私说明'), findsOneWidget);
  });

  testWidgets('清除数据取消不执行，确认只执行一次', (WidgetTester tester) async {
    int clearCount = 0;
    await tester.pumpWidget(
      MaterialApp(home: _page(onClearData: () async => clearCount += 1)),
    );
    await tester.scrollUntilVisible(find.byKey(const ValueKey<String>('clear-local-data')), 300);

    await tester.tap(find.byKey(const ValueKey<String>('clear-local-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(clearCount, 0);

    await tester.tap(find.byKey(const ValueKey<String>('clear-local-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认清除'));
    await tester.pumpAndSettle();
    expect(clearCount, 1);
    expect(find.text('本地数据已清除'), findsOneWidget);
  });
}

MinePage _page({required Future<void> Function() onClearData}) {
  return MinePage(
    config: AppConfig(
      environment: AppEnvironment.production,
      openFoodFactsBaseUri: Uri.parse('https://example.com'),
    ),
    onOpenNotificationSettings: () {},
    onClearData: onClearData,
    onCleared: () {},
  );
}
