import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/notifications/notification_navigation_service.dart';

void main() {
  test('冷启动与前台通知点击都只导航到到期提醒', () {
    final NotificationNavigationService service = NotificationNavigationService.instance;
    final List<String> routes = <String>[];

    service.handlePayload('/expirations');
    void handler(String route) => routes.add(route);
    service.attach(handler);
    service.handlePayload('/unknown');
    service.handlePayload('/expirations');
    service.detach(handler);

    expect(routes, <String>['/expirations', '/expirations']);
  });
}
