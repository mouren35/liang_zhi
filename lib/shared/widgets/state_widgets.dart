import 'package:flutter/material.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/design/app_icons.dart';

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({this.label = '正在加载', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        child: const SizedBox.square(
          dimension: AppDimensions.minimumTouchTarget,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.icon = AppIcons.empty,
    super.key,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(description, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    this.message = '暂时无法读取数据，请稍后重试',
    this.onRetry,
    this.onBack,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: AppIcons.error,
      title: '出了点小问题',
      description: message,
      actionLabel: onRetry != null ? '重试' : (onBack != null ? '返回' : null),
      onAction: onRetry ?? onBack,
    );
  }
}
