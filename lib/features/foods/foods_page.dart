import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/providers/food_providers.dart';
import 'package:liangzhi/core/providers/time_providers.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/design/app_icons.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/widgets/food_list_item.dart';
import 'package:liangzhi/shared/widgets/responsive_page.dart';
import 'package:liangzhi/shared/widgets/state_widgets.dart';

class FoodsPage extends ConsumerWidget {
  const FoodsPage({required this.onAddFood, required this.onOpenFood, super.key});

  final VoidCallback onAddFood;
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
                  child: Text('全部食物', style: Theme.of(context).textTheme.headlineMedium),
                ),
                IconButton(
                  key: const ValueKey<String>('foods-add'),
                  onPressed: onAddFood,
                  icon: const Icon(AppIcons.add),
                  tooltip: '添加食物',
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
                data: (List<Food> items) {
                  if (items.isEmpty) {
                    return EmptyStateWidget(
                      title: '还没有食物',
                      description: '添加第一件食物，开始管理家里的库存。',
                      actionLabel: '添加第一件食物',
                      onAction: onAddFood,
                    );
                  }
                  return ListView.separated(
                    key: const PageStorageKey<String>('foods-scroll'),
                    itemCount: items.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: AppSpacing.xs);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final Food food = items[index];
                      return FoodListItem(
                        key: ValueKey<String>('food-${food.id}'),
                        food: food,
                        today: today,
                        onTap: () => onOpenFood(food.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
