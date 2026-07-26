import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/providers/food_providers.dart';
import 'package:liangzhi/core/providers/time_providers.dart';
import 'package:liangzhi/shared/design/app_colors.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/design/app_icons.dart';
import 'package:liangzhi/shared/models/expiry_status.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/widgets/responsive_page.dart';
import 'package:liangzhi/shared/widgets/state_widgets.dart';

class ExpirationsPage extends ConsumerWidget {
  const ExpirationsPage({
    required this.onOpenSettings,
    required this.onOpenFood,
    super.key,
  });

  final VoidCallback onOpenSettings;
  final ValueChanged<String> onOpenFood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Food>> foods = ref.watch(foodListProvider);
    final DateTime today = ref.watch(currentDateProvider);
    return Scaffold(
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('到期提醒', style: Theme.of(context).textTheme.headlineMedium),
                ),
                IconButton(
                  onPressed: onOpenSettings,
                  icon: const Icon(AppIcons.settings),
                  tooltip: '通知设置',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: foods.when(
                loading: () => const LoadingStateWidget(),
                error: (Object error, StackTrace stack) => ErrorStateWidget(
                  onRetry: () => ref.invalidate(foodListProvider),
                ),
                data: (List<Food> items) => _ExpirationGroups(
                  foods: items,
                  today: today,
                  onOpenFood: onOpenFood,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpirationGroups extends StatelessWidget {
  const _ExpirationGroups({
    required this.foods,
    required this.today,
    required this.onOpenFood,
  });

  final List<Food> foods;
  final DateTime today;
  final ValueChanged<String> onOpenFood;

  @override
  Widget build(BuildContext context) {
    final Map<ExpiryStatus, List<Food>> groups = <ExpiryStatus, List<Food>>{
      ExpiryStatus.expiring: <Food>[],
      ExpiryStatus.dueToday: <Food>[],
      ExpiryStatus.expired: <Food>[],
    };
    for (final Food food in foods) {
      groups[calculateExpiryStatus(food, today: today)]?.add(food);
    }
    if (groups.values.every((List<Food> items) => items.isEmpty)) {
      return const EmptyStateWidget(
        title: '暂时没有到期提醒',
        description: '需要关注的食物会按时间出现在这里。',
        icon: AppIcons.expirations,
      );
    }
    return ListView(
      key: const PageStorageKey<String>('expirations-scroll'),
      children: [
        _ExpirationGroup(
          title: '建议近期享用',
          foods: groups[ExpiryStatus.expiring]!,
          color: AppColors.expiring,
          onOpenFood: onOpenFood,
        ),
        _ExpirationGroup(
          title: '今天优先处理',
          foods: groups[ExpiryStatus.dueToday]!,
          color: AppColors.accent,
          onOpenFood: onOpenFood,
        ),
        _ExpirationGroup(
          title: '已超过记录日期',
          foods: groups[ExpiryStatus.expired]!,
          color: AppColors.error,
          onOpenFood: onOpenFood,
        ),
      ],
    );
  }
}

class _ExpirationGroup extends StatelessWidget {
  const _ExpirationGroup({
    required this.title,
    required this.foods,
    required this.color,
    required this.onOpenFood,
  });

  final String title;
  final List<Food> foods;
  final Color color;
  final ValueChanged<String> onOpenFood;

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Text(
                  '$title · ${foods.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
                ),
              ),
              for (final Food food in foods)
                ListTile(
                  minTileHeight: AppDimensions.minimumTouchTarget,
                  onTap: () => onOpenFood(food.id),
                  title: Text(food.name),
                  subtitle: Text(formatLocalDate(food.expiryDate)),
                  trailing: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
