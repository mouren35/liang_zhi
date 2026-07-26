import 'package:flutter/material.dart';
import 'package:liangzhi/app/app_config.dart';
import 'package:liangzhi/app/app_info.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/design/app_icons.dart';
import 'package:liangzhi/shared/widgets/responsive_page.dart';
import 'package:liangzhi/shared/widgets/feedback.dart';

class MinePage extends StatelessWidget {
  const MinePage({
    required this.config,
    required this.onOpenNotificationSettings,
    required this.onClearData,
    super.key,
  });

  final AppConfig config;
  final VoidCallback onOpenNotificationSettings;
  final Future<void> Function() onClearData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsivePage(
        child: ListView(
          key: const PageStorageKey<String>('mine-scroll'),
          children: [
            Text('我的', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: '应用信息',
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text(AppInfo.name),
                  subtitle: Text('版本 ${AppInfo.version}（${AppInfo.buildNumber}）'),
                ),
                if (config.showEnvironmentBadge)
                  ListTile(
                    leading: const Icon(Icons.developer_mode_outlined),
                    title: const Text('当前环境'),
                    subtitle: Text(config.environment.label),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: '提醒与数据',
              children: [
                ListTile(
                  minTileHeight: AppDimensions.minimumTouchTarget,
                  leading: const Icon(AppIcons.notification),
                  title: const Text('通知设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenNotificationSettings,
                ),
                const ListTile(
                  leading: Icon(Icons.phone_android_outlined),
                  title: Text('数据存储'),
                  subtitle: Text('食品库存、数量和日期仅保存在当前设备。'),
                ),
                const ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('联网范围'),
                  subtitle: Text('仅在扫码时通过 HTTPS 查询 Open Food Facts 商品基础信息。'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _Section(
              title: '数据来源与隐私',
              children: [
                ListTile(
                  leading: Icon(Icons.public_outlined),
                  title: Text('Open Food Facts'),
                  subtitle: Text('商品数据来自 Open Food Facts，数据库采用 ODbL 许可，图片按各自许可使用。'),
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('隐私说明'),
                  subtitle: Text('不会上传家庭库存、数量、生产日期、到期日期或备注。'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const ValueKey<String>('clear-local-data'),
              onPressed: () => _confirmClear(context),
              icon: const Icon(AppIcons.delete),
              label: const Text('清除本地数据'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bool confirmed = await showConfirmationDialog(
      context: context,
      title: '清除本地数据？',
      message: '食品、条码缓存、设置和待处理提醒将被删除，此操作无法撤销。',
      confirmLabel: '确认清除',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await onClearData();
      if (context.mounted) {
        showSuccessMessage(context, '本地数据已清除');
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('清除失败，请稍后重试')));
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Card(child: Column(children: children)),
      ],
    );
  }
}
