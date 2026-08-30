import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/bootstrap.dart';

void main() {
  testWidgets('初始化失败时显示友好兜底而不是白屏', (WidgetTester tester) async {
    await bootstrap(
      initializeDatabase: () async => throw StateError('test'),
      initializeSettings: () async {},
      initializeNotifications: () async {},
    );
    await tester.pump();

    expect(find.text('粮知暂时无法启动，请稍后重试'), findsOneWidget);
  });

  testWidgets('彼此独立的启动任务并行执行', (WidgetTester tester) async {
    final Completer<void> gate = Completer<void>();
    int startedTasks = 0;

    Future<void> waitForGate() async {
      startedTasks += 1;
      await gate.future;
    }

    final Future<void> bootstrapFuture = bootstrap(
      initializeDatabase: waitForGate,
      initializeSettings: waitForGate,
      initializeNotifications: waitForGate,
    );
    await tester.pump();

    expect(startedTasks, 3);

    gate.completeError(StateError('test'));
    await bootstrapFuture;
    await tester.pump();

    expect(find.text('粮知暂时无法启动，请稍后重试'), findsOneWidget);
  });
}
