import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';
import 'package:liangzhi/core/notifications/flutter_notification_platform.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/providers/repository_providers.dart';
import 'package:liangzhi/core/providers/service_providers.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/reference_item.dart';
import 'package:liangzhi/shared/repositories/food_repository.dart';
import 'package:liangzhi/shared/repositories/reference_data_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android 首次成功保存后展示系统通知权限请求',
    (WidgetTester tester) async {
      if (!Platform.isAndroid) {
        return;
      }

      timezone_data.initializeTimeZones();
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.clear();
      final SettingsService settings = SettingsService.forTesting(preferences);
      // 本用例只验收权限；关闭调度可避免在设备上留下测试提醒。
      await settings.setRemindersEnabled(false);
      final _MemoryFoodRepository foods = _MemoryFoodRepository();
      final FlutterNotificationPlatform platform = FlutterNotificationPlatform.instance;
      await platform.initialize(onNotificationTap: (String payload) {});

      final NotificationPermissionStatus beforeSave = await platform.permissionStatus(
        permissionRequested: false,
      );
      expect(beforeSave, NotificationPermissionStatus.notDetermined);
      // 供设备验收脚本确认保存前状态。
      // ignore: avoid_print
      print('PLATFORM_PERMISSION_BEFORE_SAVE=${beforeSave.name}');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsServiceProvider.overrideWithValue(settings),
            foodRepositoryProvider.overrideWithValue(foods),
            categoryRepositoryProvider.overrideWithValue(
              const _CategoryRepository(),
            ),
            locationRepositoryProvider.overrideWithValue(
              const _LocationRepository(),
            ),
          ],
          child: LiangZhiApp(
            config: AppConfig(
              environment: AppEnvironment.test,
              openFoodFactsBaseUri: Uri.parse('https://example.com'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部食物').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加第一件食物'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('food-name')),
        '权限验收牛奶',
      );
      final Finder expiryDate = find.byKey(
        const ValueKey<String>('expiry-date'),
      );
      await tester.ensureVisible(expiryDate);
      await tester.tap(expiryDate);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final Finder save = find.byKey(const ValueKey<String>('save-food'));
      await tester.ensureVisible(save);
      // ignore: avoid_print
      print('PLATFORM_PERMISSION_TAP_SAVE');
      await tester.tap(save);

      NotificationPermissionStatus afterSave = NotificationPermissionStatus.notDetermined;
      for (int second = 0; second < 180; second++) {
        await tester.runAsync<void>(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        afterSave = await platform.permissionStatus(
          permissionRequested: true,
        );
        if (afterSave == NotificationPermissionStatus.granted) {
          break;
        }
      }
      // ignore: avoid_print
      print('PLATFORM_PERMISSION_AFTER_SAVE=${afterSave.name}');
      await tester.pump();

      expect(foods.saved, hasLength(1));
      expect(settings.read().notificationPermissionRequested, isTrue);
      expect(afterSave, NotificationPermissionStatus.granted);
      await foods.close();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

final class _MemoryFoodRepository implements FoodRepository {
  final List<Food> saved = <Food>[];
  final StreamController<List<Food>> _changes = StreamController<List<Food>>.broadcast();

  Future<void> close() => _changes.close();

  @override
  Future<void> add(Food food) async {
    saved.add(food);
    _changes.add(List<Food>.unmodifiable(saved));
  }

  @override
  Future<List<Food>> getActiveFoods() async => List<Food>.unmodifiable(saved);

  @override
  Future<Food> getById(String id) async => saved.singleWhere((Food food) => food.id == id);

  @override
  Future<void> softDelete(String id, {required DateTime deletedAt}) async {}

  @override
  Future<void> update(Food food) async {}

  @override
  Stream<List<Food>> watchActiveFoods() async* {
    yield List<Food>.unmodifiable(saved);
    yield* _changes.stream;
  }
}

final class _CategoryRepository implements CategoryRepository {
  const _CategoryRepository();

  static const ReferenceItem other = ReferenceItem(
    id: DefaultIds.categoryOther,
    name: '其他',
    isSystem: true,
  );

  @override
  Future<List<ReferenceItem>> getAll() async => const <ReferenceItem>[other];

  @override
  Future<ReferenceItem?> getDefault() async => other;
}

final class _LocationRepository implements LocationRepository {
  const _LocationRepository();

  static const ReferenceItem other = ReferenceItem(
    id: DefaultIds.locationOther,
    name: '其他',
    isSystem: true,
  );

  @override
  Future<List<ReferenceItem>> getAll() async => const <ReferenceItem>[other];

  @override
  Future<ReferenceItem?> getDefault() async => other;
}
