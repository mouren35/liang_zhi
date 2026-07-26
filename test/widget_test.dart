import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/main.dart';

void main() {
  testWidgets('显示粮知占位首页', (WidgetTester tester) async {
    await tester.pumpWidget(const LiangZhiApp());

    expect(find.text('粮知'), findsOneWidget);
  });
}
