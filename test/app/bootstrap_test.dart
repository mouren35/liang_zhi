import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/bootstrap.dart';

void main() {
  testWidgets('初始化失败时显示友好兜底而不是白屏', (WidgetTester tester) async {
    await bootstrap(initializeDatabase: () async => throw StateError('test'));
    await tester.pump();

    expect(find.text('粮知暂时无法启动，请稍后重试'), findsOneWidget);
  });
}
