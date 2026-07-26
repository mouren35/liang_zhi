import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/core/providers/food_providers.dart';
import 'package:liangzhi/core/providers/reference_providers.dart';
import 'package:liangzhi/shared/design/app_colors.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/design/app_icons.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/reference_item.dart';
import 'package:liangzhi/shared/widgets/responsive_page.dart';
import 'package:liangzhi/shared/widgets/state_widgets.dart';

class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({
    required this.foodId,
    required this.onBack,
    required this.onEdit,
    super.key,
  });

  final String foodId;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Food> food = ref.watch(foodDetailProvider(foodId));
    return Scaffold(
      body: ResponsivePage(
        child: food.when(
          loading: () => const LoadingStateWidget(),
          error: (Object error, StackTrace stack) {
            if (error is DataNotFoundException) {
              return ErrorStateWidget(message: '食品不存在或已经删除', onBack: onBack);
            }
            return ErrorStateWidget(
              onRetry: () => ref.invalidate(foodDetailProvider(foodId)),
              onBack: onBack,
            );
          },
          data: (Food value) => _FoodDetails(food: value, onBack: onBack, onEdit: onEdit),
        ),
      ),
    );
  }
}

class _FoodDetails extends ConsumerWidget {
  const _FoodDetails({required this.food, required this.onBack, required this.onEdit});

  final Food food;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ReferenceItem>> categories = ref.watch(categoryListProvider);
    final AsyncValue<List<ReferenceItem>> locations = ref.watch(locationListProvider);
    return ListView(
      children: [
        Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(AppIcons.back), tooltip: '返回'),
            Expanded(
              child: Text(food.name, style: Theme.of(context).textTheme.headlineMedium),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 180,
          decoration: const BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: AppRadii.card,
          ),
          child: const Icon(AppIcons.foods, size: 72),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(label: '数量', value: '${food.quantity} ${food.unit}'),
        _DetailRow(label: '分类', value: _referenceName(categories, food.categoryId)),
        _DetailRow(label: '存放位置', value: _referenceName(locations, food.locationId)),
        _DetailRow(label: '到期日期', value: formatLocalDate(food.expiryDate)),
        _DetailRow(
          label: '创建时间',
          value: DateFormat('yyyy-MM-dd HH:mm').format(food.createdAt.toLocal()),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(AppIcons.edit),
          label: const Text('编辑（后续版本完善）'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          color: AppColors.surfaceWarm,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('食谱建议', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                const Text('后续版本提供'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppDimensions.minimumTouchTarget),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

String _referenceName(AsyncValue<List<ReferenceItem>> items, String? id) {
  if (id == null) {
    return '未设置';
  }
  return items.when(
    data: (List<ReferenceItem> values) =>
        values.where((ReferenceItem item) => item.id == id).firstOrNull?.name ?? '未设置',
    loading: () => '读取中',
    error: (Object error, StackTrace stack) => '未设置',
  );
}
