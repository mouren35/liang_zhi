import 'package:flutter/foundation.dart';

typedef LogOutput = void Function(String message);

final class SafeLogger {
  SafeLogger({required this.enabled, LogOutput? output}) : output = output ?? debugPrint;

  final bool enabled;
  final LogOutput output;

  void event(String name) {
    if (!enabled) {
      return;
    }
    output('event=${_safeEventName(name)}');
  }

  void error(String name, Object error) {
    if (!enabled) {
      return;
    }
    output('event=${_safeEventName(name)} error_type=${error.runtimeType}');
  }
}

String _safeEventName(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(value)) {
    throw ArgumentError.value(value, 'name', '日志事件名必须是内部 snake_case 标识');
  }
  return value;
}
