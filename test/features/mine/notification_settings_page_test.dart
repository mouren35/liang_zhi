import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/notifications/notification_platform.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/features/mine/notification_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SettingsKeys.notificationPermissionRequested: true,
    });
  });

  testWidgets('显示永久拒绝说明、打开系统设置并持久化总开关', (
    WidgetTester tester,
  ) async {
    final SettingsService settings = SettingsService.forTesting(
      await SharedPreferences.getInstance(),
    );
    final _FakeNotificationPlatform platform = _FakeNotificationPlatform();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsServiceProvider.overrideWithValue(settings),
          foodRepositoryProvider.overrideWithValue(
            const EmptyFoodRepository(),
          ),
          notificationPlatformProvider.overrideWithValue(platform),
        ],
        child: MaterialApp(
          home: NotificationSettingsPage(onBack: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('通知权限已关闭，请在系统设置中开启'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('open-notification-settings')),
    );
    await tester.pump();
    expect(platform.openSettingsCount, 1);

    await tester.tap(
      find.byKey(const ValueKey<String>('reminders-enabled')),
    );
    await tester.pumpAndSettle();
    expect(settings.read().remindersEnabled, isFalse);
    expect(platform.cancelCount, greaterThanOrEqualTo(1));
  });
}

final class _FakeNotificationPlatform implements NotificationPlatform {
  int openSettingsCount = 0;
  int cancelCount = 0;

  @override
  Future<void> cancelAll() async {
    cancelCount += 1;
  }

  @override
  Future<void> initialize({
    required void Function(String payload) onNotificationTap,
  }) async {}

  @override
  Future<void> openSystemSettings() async {
    openSettingsCount += 1;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus({
    required bool permissionRequested,
  }) async => NotificationPermissionStatus.permanentlyDenied;

  @override
  Future<void> replaceScheduled(
    List<LocalNotificationRequest> notifications,
  ) async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.permanentlyDenied;
}
