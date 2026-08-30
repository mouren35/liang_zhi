import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android 只声明通知调度所需权限和接收器，不申请精确闹钟', () {
    final String manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    expect(manifest, contains('ScheduledNotificationReceiver'));
    expect(manifest, contains('ScheduledNotificationBootReceiver'));
    expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
    expect(manifest, isNot(contains('USE_EXACT_ALARM')));
  });

  test('iOS 初始化不在启动时自动申请通知权限', () {
    final String bootstrap = File(
      'lib/core/notifications/flutter_notification_platform.dart',
    ).readAsStringSync();

    expect(bootstrap, contains('requestAlertPermission: false'));
    expect(bootstrap, contains('requestBadgePermission: false'));
    expect(bootstrap, contains('requestSoundPermission: false'));
  });
}
