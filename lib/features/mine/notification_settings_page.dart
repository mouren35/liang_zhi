import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/notifications/notification_models.dart';
import 'package:liangzhi/core/providers/notification_providers.dart';
import 'package:liangzhi/core/settings/settings_service.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/widgets/responsive_page.dart';
import 'package:liangzhi/shared/widgets/state_widgets.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> settings = ref.watch(
      notificationSettingsControllerProvider,
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        title: const Text('通知设置'),
      ),
      body: ResponsivePage(
        child: settings.when(
          loading: () => const LoadingStateWidget(),
          error: (Object error, StackTrace stack) => ErrorStateWidget(
            message: '通知设置暂时无法读取',
            onRetry: () => ref.invalidate(notificationSettingsControllerProvider),
          ),
          data: (AppSettings value) => _SettingsList(settings: value),
        ),
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationSettingsController controller = ref.read(
      notificationSettingsControllerProvider.notifier,
    );
    final AsyncValue<NotificationPermissionStatus> permission = ref.watch(
      notificationPermissionStatusProvider,
    );
    final bool enabled = settings.remindersEnabled;
    final List<int> reminderDayOptions = <int>{
      -1,
      1,
      3,
      7,
      ?settings.globalReminderDaysOverride,
    }.toList()..sort();
    final List<int> longTermDayOptions = <int>{
      15,
      30,
      45,
      60,
      settings.longTermReminderDays,
    }.toList()..sort();
    return ListView(
      children: [
        _PermissionCard(
          permission: permission,
          onOpenSettings: controller.openSystemSettings,
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          key: const ValueKey<String>('reminders-enabled'),
          title: const Text('启用提醒'),
          subtitle: const Text('关闭后取消所有待处理通知'),
          value: settings.remindersEnabled,
          onChanged: controller.setRemindersEnabled,
        ),
        ListTile(
          key: const ValueKey<String>('reminder-time'),
          enabled: enabled,
          title: const Text('每日提醒时间'),
          subtitle: Text(settings.reminderTime),
          trailing: const Icon(Icons.schedule_outlined),
          onTap: enabled ? () => _pickTime(context, controller, settings.reminderTime) : null,
        ),
        SwitchListTile(
          key: const ValueKey<String>('daily-summary-enabled'),
          title: const Text('每日到期汇总'),
          subtitle: const Text('临期、今日到期和已过期合并为一条'),
          value: settings.dailySummaryEnabled,
          onChanged: enabled ? controller.setDailySummaryEnabled : null,
        ),
        SwitchListTile(
          key: const ValueKey<String>('remind-expired'),
          title: const Text('包含已过期食品'),
          value: settings.remindExpired,
          onChanged: enabled && settings.dailySummaryEnabled ? controller.setRemindExpired : null,
        ),
        ListTile(
          enabled: enabled && settings.dailySummaryEnabled,
          title: const Text('统一提前提醒'),
          subtitle: const Text('默认按食品保质期自动计算'),
          trailing: DropdownButton<int>(
            value: settings.globalReminderDaysOverride ?? -1,
            onChanged: enabled && settings.dailySummaryEnabled
                ? (int? value) {
                    if (value != null) {
                      controller.setGlobalReminderDaysOverride(
                        value == -1 ? null : value,
                      );
                    }
                  }
                : null,
            items: reminderDayOptions
                .map(
                  (int days) => DropdownMenuItem<int>(
                    value: days,
                    child: Text(days == -1 ? '自动' : '$days 天'),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        SwitchListTile(
          key: const ValueKey<String>('long-term-enabled'),
          title: const Text('长期未更新提醒'),
          value: settings.longTermReminderEnabled,
          onChanged: enabled ? controller.setLongTermReminderEnabled : null,
        ),
        ListTile(
          enabled: enabled && settings.longTermReminderEnabled,
          title: const Text('未更新天数'),
          trailing: DropdownButton<int>(
            value: settings.longTermReminderDays,
            onChanged: enabled && settings.longTermReminderEnabled
                ? (int? value) {
                    if (value != null) {
                      controller.setLongTermReminderDays(value);
                    }
                  }
                : null,
            items: longTermDayOptions
                .map(
                  (int days) => DropdownMenuItem<int>(
                    value: days,
                    child: Text('$days 天'),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    NotificationSettingsController controller,
    String current,
  ) async {
    final List<String> parts = current.split(':');
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts.first),
        minute: int.parse(parts.last),
      ),
    );
    if (selected == null) {
      return;
    }
    final String value =
        '${selected.hour.toString().padLeft(2, '0')}:'
        '${selected.minute.toString().padLeft(2, '0')}';
    await controller.setReminderTime(value);
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.permission,
    required this.onOpenSettings,
  });

  final AsyncValue<NotificationPermissionStatus> permission;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final NotificationPermissionStatus? status = permission.value;
    final bool needsSettings =
        status == NotificationPermissionStatus.denied ||
        status == NotificationPermissionStatus.permanentlyDenied;
    final String message = switch (status) {
      NotificationPermissionStatus.granted => '系统通知权限已开启',
      NotificationPermissionStatus.denied => '通知权限已拒绝，可在系统设置中开启',
      NotificationPermissionStatus.permanentlyDenied => '通知权限已关闭，请在系统设置中开启',
      NotificationPermissionStatus.notDetermined => '首次成功添加食品后会申请通知权限',
      null => '正在读取系统通知权限',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('系统权限', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message),
            if (needsSettings) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                key: const ValueKey<String>('open-notification-settings'),
                onPressed: onOpenSettings,
                child: const Text('打开系统设置'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
