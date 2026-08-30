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

class HomePage extends ConsumerWidget {
  const HomePage({required this.onAddFood, required this.onOpenExpirations, super.key});

  final VoidCallback onAddFood;
  final VoidCallback onOpenExpirations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Food>> foods = ref.watch(foodListProvider);
    final DateTime today = ref.watch(currentDateProvider);
    return Scaffold(
      body: ResponsivePage(
        child: foods.when(
          loading: () => const LoadingStateWidget(),
          error: (Object error, StackTrace stack) => ErrorStateWidget(
            onRetry: () => ref.invalidate(foodListProvider),
          ),
          data: (List<Food> items) => ListView(
            key: const PageStorageKey<String>('home-scroll'),
            children: [
              Text('粮知', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '让每一份食物，都在合适的时候被享用。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              _InventoryOverview(foods: items, today: today),
              const SizedBox(height: AppSpacing.md),
              _ExpirySummary(foods: items, today: today, onTap: onOpenExpirations),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const ValueKey<String>('home-add-food'),
                onPressed: onAddFood,
                icon: const Icon(AppIcons.add),
                label: const Text('快速添加食物'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryOverview extends StatelessWidget {
  const _InventoryOverview({required this.foods, required this.today});

  final List<Food> foods;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final int expiring = foods
        .where(
          (Food food) => calculateExpiryStatus(food, today: today) == ExpiryStatus.expiring,
        )
        .length;
    final int expired = foods
        .where(
          (Food food) => calculateExpiryStatus(food, today: today) == ExpiryStatus.expired,
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('库存概览', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _MetricCard(label: '当前库存', value: foods.length, color: AppColors.accent),
            _MetricCard(label: '建议近期享用', value: expiring, color: AppColors.expiring),
            _MetricCard(label: '已超过记录日期', value: expired, color: AppColors.error),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpirySummary extends StatelessWidget {
  const _ExpirySummary({required this.foods, required this.today, required this.onTap});

  final List<Food> foods;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int attentionCount = foods
        .where(
          (Food food) => calculateExpiryStatus(food, today: today) != ExpiryStatus.fresh,
        )
        .length;
    return Card(
      color: AppColors.surfaceWarm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(AppIcons.expirations, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('到期提醒', style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      attentionCount == 0 ? '当前没有需要优先处理的食物' : '$attentionCount 件食物值得近期关注',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
