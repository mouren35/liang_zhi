import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/widgets/feedback.dart';
import 'package:liangzhi/shared/widgets/state_widgets.dart';

void main() {
  testWidgets('空状态可选操作可点击', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: EmptyStateWidget(
          title: '暂无数据',
          description: '说明',
          actionLabel: '开始添加',
          onAction: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('开始添加'));
    expect(tapped, isTrue);
  });

  testWidgets('错误状态只显示友好文案并支持重试', (WidgetTester tester) async {
    bool retried = false;
    await tester.pumpWidget(
      MaterialApp(home: ErrorStateWidget(onRetry: () => retried = true)),
    );

    expect(find.text('暂时无法读取数据，请稍后重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retried, isTrue);
  });

  testWidgets('统一确认框返回取消和确认结果', (WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () async {
                result = await showConfirmationDialog(
                  context: context,
                  title: '确认操作？',
                  message: '说明',
                  confirmLabel: '确认',
                );
              },
              child: const Text('打开'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
