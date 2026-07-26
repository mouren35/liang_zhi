import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/app/liang_zhi_app.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/global_error_handler.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/database/default_data.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:timezone/data/latest.dart' as timezone_data;

typedef InitializationTask = Future<void> Function();

Future<void> bootstrap({
  InitializationTask? initializeDatabase,
  InitializationTask? initializeSettings,
  InitializationTask? initializeNotifications,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers(AppConfig.current);

  try {
    await (initializeDatabase ?? _initializeDatabase)();
    await (initializeSettings ?? _initializeSettings)();
    await (initializeNotifications ?? _initializeNotifications)();
    runApp(ProviderScope(child: LiangZhiApp()));
  } on Object {
    runApp(const _InitializationFailureApp());
  }
}

Future<void> _initializeDatabase() async {
  await AppDatabase.instance.ensureOpen();
  await initializeDefaultData(AppDatabase.instance);
}

Future<void> _initializeSettings() async {
  await SettingsService.initialize();
}

Future<void> _initializeNotifications() async {
  timezone_data.initializeTimeZones();
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }

  const InitializationSettings settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await FlutterLocalNotificationsPlugin().initialize(settings: settings);
}

class _InitializationFailureApp extends StatelessWidget {
  const _InitializationFailureApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('粮知暂时无法启动，请稍后重试'))),
    );
  }
}
