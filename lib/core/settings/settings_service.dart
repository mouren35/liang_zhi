import 'package:shared_preferences/shared_preferences.dart';

abstract final class SettingsKeys {
  static const String hasCompletedInitialLaunch = 'v1.has_completed_initial_launch';
  static const String foodListViewMode = 'v1.food_list_view_mode';
  static const String remindersEnabled = 'v1.reminders_enabled';
  static const String reminderTime = 'v1.reminder_time';
  static const String globalReminderDaysOverride = 'v1.global_reminder_days_override';
  static const String remindExpired = 'v1.remind_expired';
  static const String dailySummaryEnabled = 'v1.daily_summary_enabled';
  static const String longTermReminderEnabled = 'v1.long_term_reminder_enabled';
  static const String longTermReminderDays = 'v1.long_term_reminder_days';

  static const Set<String> all = <String>{
    hasCompletedInitialLaunch,
    foodListViewMode,
    remindersEnabled,
    reminderTime,
    globalReminderDaysOverride,
    remindExpired,
    dailySummaryEnabled,
    longTermReminderEnabled,
    longTermReminderDays,
  };
}

enum FoodListViewMode {
  list('list')
  ;

  const FoodListViewMode(this.storageValue);

  final String storageValue;

  static FoodListViewMode fromStorage(String? value) {
    return FoodListViewMode.values.firstWhere(
      (FoodListViewMode mode) => mode.storageValue == value,
      orElse: () => FoodListViewMode.list,
    );
  }
}

final class AppSettings {
  const AppSettings({
    required this.hasCompletedInitialLaunch,
    required this.foodListViewMode,
    required this.remindersEnabled,
    required this.reminderTime,
    required this.globalReminderDaysOverride,
    required this.remindExpired,
    required this.dailySummaryEnabled,
    required this.longTermReminderEnabled,
    required this.longTermReminderDays,
  });

  final bool hasCompletedInitialLaunch;
  final FoodListViewMode foodListViewMode;
  final bool remindersEnabled;
  final String reminderTime;
  final int? globalReminderDaysOverride;
  final bool remindExpired;
  final bool dailySummaryEnabled;
  final bool longTermReminderEnabled;
  final int longTermReminderDays;
}

final class SettingsService {
  SettingsService.forTesting(this._preferences);

  static SettingsService? _instance;

  final SharedPreferences _preferences;

  static Future<SettingsService> initialize() async {
    return _instance ??= SettingsService.forTesting(await SharedPreferences.getInstance());
  }

  static SettingsService get instance {
    final SettingsService? service = _instance;
    if (service == null) {
      throw StateError('SettingsService 尚未初始化');
    }
    return service;
  }

  AppSettings read() {
    return AppSettings(
      hasCompletedInitialLaunch:
          _preferences.getBool(SettingsKeys.hasCompletedInitialLaunch) ?? false,
      foodListViewMode: FoodListViewMode.fromStorage(
        _preferences.getString(SettingsKeys.foodListViewMode),
      ),
      remindersEnabled: _preferences.getBool(SettingsKeys.remindersEnabled) ?? true,
      reminderTime: _validReminderTime(
        _preferences.getString(SettingsKeys.reminderTime),
      ),
      globalReminderDaysOverride: _nonNegativeOrNull(
        _preferences.getInt(SettingsKeys.globalReminderDaysOverride),
      ),
      remindExpired: _preferences.getBool(SettingsKeys.remindExpired) ?? true,
      dailySummaryEnabled: _preferences.getBool(SettingsKeys.dailySummaryEnabled) ?? true,
      longTermReminderEnabled: _preferences.getBool(SettingsKeys.longTermReminderEnabled) ?? true,
      longTermReminderDays: _positiveOrDefault(
        _preferences.getInt(SettingsKeys.longTermReminderDays),
        fallback: 30,
      ),
    );
  }

  Future<void> setHasCompletedInitialLaunch(bool value) {
    return _preferences.setBool(SettingsKeys.hasCompletedInitialLaunch, value);
  }

  Future<void> setFoodListViewMode(FoodListViewMode value) {
    return _preferences.setString(SettingsKeys.foodListViewMode, value.storageValue);
  }

  Future<void> setRemindersEnabled(bool value) {
    return _preferences.setBool(SettingsKeys.remindersEnabled, value);
  }

  Future<void> setReminderTime(String value) {
    if (_validReminderTime(value) != value) {
      throw const FormatException('提醒时间格式必须为 HH:mm');
    }
    return _preferences.setString(SettingsKeys.reminderTime, value);
  }

  Future<void> setGlobalReminderDaysOverride(int? value) async {
    if (value == null) {
      await _preferences.remove(SettingsKeys.globalReminderDaysOverride);
      return;
    }
    if (value < 0) {
      throw const FormatException('提前提醒天数不能小于 0');
    }
    await _preferences.setInt(SettingsKeys.globalReminderDaysOverride, value);
  }

  Future<void> setRemindExpired(bool value) {
    return _preferences.setBool(SettingsKeys.remindExpired, value);
  }

  Future<void> setDailySummaryEnabled(bool value) {
    return _preferences.setBool(SettingsKeys.dailySummaryEnabled, value);
  }

  Future<void> setLongTermReminderEnabled(bool value) {
    return _preferences.setBool(SettingsKeys.longTermReminderEnabled, value);
  }

  Future<void> setLongTermReminderDays(int value) {
    if (value <= 0) {
      throw const FormatException('长期未更新天数必须大于 0');
    }
    return _preferences.setInt(SettingsKeys.longTermReminderDays, value);
  }

  Future<void> clear() async {
    for (final String key in SettingsKeys.all) {
      await _preferences.remove(key);
    }
  }
}

String _validReminderTime(String? value) {
  if (value == null || !RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
    return '09:00';
  }
  return value;
}

int? _nonNegativeOrNull(int? value) => value != null && value >= 0 ? value : null;

int _positiveOrDefault(int? value, {required int fallback}) {
  return value != null && value > 0 ? value : fallback;
}
