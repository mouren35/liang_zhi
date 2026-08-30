import 'package:flutter/services.dart';

abstract final class SystemSettingsService {
  static const MethodChannel _channel = MethodChannel(
    'com.liangzhi.app/system_settings',
  );

  static Future<void> openAppSettings() async {
    await _channel.invokeMethod<void>('openAppSettings');
  }
}
