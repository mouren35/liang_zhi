import 'package:flutter/material.dart';
import 'package:liangzhi/shared/design/app_colors.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/design/app_icons.dart';
import 'package:liangzhi/shared/models/expiry_status.dart';
import 'package:liangzhi/shared/models/food.dart';

class FoodListItem extends StatelessWidget {
  const FoodListItem({
    required this.food,
    required this.today,
    required this.onTap,
    super.key,
  });

  final Food food;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ExpiryStatus status = calculateExpiryStatus(food, today: today);
    final Color dateColor = switch (status) {
      ExpiryStatus.expired => AppColors.error,
      ExpiryStatus.dueToday => AppColors.accent,
      ExpiryStatus.expiring => AppColors.expiring,
      ExpiryStatus.fresh => AppColors.textSecondary,
    };
    return Semantics(
      button: true,
      label: '查看${food.name}详情',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.card,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppDimensions.minimumTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: AppRadii.input,
                    ),
                    child: const Icon(AppIcons.foods),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '到期 ${formatLocalDate(food.expiryDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: dateColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('${food.quantity} ${food.unit}', textAlign: TextAlign.end),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
