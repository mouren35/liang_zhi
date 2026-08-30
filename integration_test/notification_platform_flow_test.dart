import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liangzhi/core/notifications/flutter_notification_platform.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:timezone/data/latest.dart' as timezone_data;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android 实际展示通知并在点击后进入到期提醒',
    (WidgetTester tester) async {
      if (!Platform.isAndroid) {
        return;
      }

      timezone_data.initializeTimeZones();
      final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
      final Completer<void> notificationTapped = Completer<void>();
      final FlutterNotificationPlatform platform = FlutterNotificationPlatform.instance;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          initialRoute: '/',
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => const Scaffold(body: Center(child: Text('通知平台验收'))),
            '/expirations': (BuildContext context) =>
                const Scaffold(body: Center(child: Text('到期提醒验收页'))),
          },
        ),
      );
      await platform.initialize(
        onNotificationTap: (String payload) {
          if (payload != '/expirations') {
            return;
          }
          navigatorKey.currentState?.pushNamed(payload);
          if (!notificationTapped.isCompleted) {
            notificationTapped.complete();
          }
        },
      );

      final DateTime now = DateTime.now();
      final DateTime scheduledAt = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      ).add(const Duration(minutes: 2));
      await platform.replaceScheduled(
        <LocalNotificationRequest>[
          LocalNotificationRequest(
            id: 9191,
            kind: LocalNotificationKind.dailySummary,
            scheduledAt: scheduledAt,
            title: '粮知通知验收',
            body: '点击进入到期提醒',
            payload: '/expirations',
          ),
        ],
      );
      // 供设备验收脚本读取，随后将应用切到后台并点击系统通知。
      // ignore: avoid_print
      print(
        'PLATFORM_NOTIFICATION_SCHEDULED_AT=${scheduledAt.toIso8601String()}',
      );

      await tester.runAsync<void>(
        () => notificationTapped.future.timeout(const Duration(minutes: 4)),
      );
      await tester.pumpAndSettle();

      expect(find.text('到期提醒验收页'), findsOneWidget);
      await platform.cancelAll();
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
