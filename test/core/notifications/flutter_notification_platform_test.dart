import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/notifications/flutter_notification_platform.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:timezone/data/latest.dart' as timezone_data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  timezone_data.initializeTimeZones();
  const MethodChannel channel = MethodChannel(
    'com.liangzhi.app/notification_permission',
  );

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  test('系统 GMT/UTC 别名归一化为时区数据库中的 UTC', () {
    expect(resolveTimezoneLocation('GMT').name, 'Etc/UTC');
    expect(resolveTimezoneLocation('UTC').name, 'Etc/UTC');
    expect(resolveTimezoneLocation('Asia/Shanghai').name, 'Asia/Shanghai');
  });

  test('平台权限状态完整映射且传递是否已请求标记', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    bool? capturedRequested;
    String response = 'notDetermined';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async {
        capturedRequested = (call.arguments as Map<Object?, Object?>)['requested'] as bool?;
        return response;
      },
    );

    for (final (String value, NotificationPermissionStatus expected)
        in <(String, NotificationPermissionStatus)>[
          ('notDetermined', NotificationPermissionStatus.notDetermined),
          ('granted', NotificationPermissionStatus.granted),
          ('denied', NotificationPermissionStatus.denied),
          (
            'permanentlyDenied',
            NotificationPermissionStatus.permanentlyDenied,
          ),
        ]) {
      response = value;
      expect(
        await FlutterNotificationPlatform.instance.permissionStatus(
          permissionRequested: true,
        ),
        expected,
      );
    }
    expect(capturedRequested, isTrue);
  });
}
