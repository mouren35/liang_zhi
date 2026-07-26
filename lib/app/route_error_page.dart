import 'package:flutter/material.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/design/app_icons.dart';

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({required this.onReturnHome, this.message = '没有找到这个页面', super.key});

  final String message;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.error, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(message, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onReturnHome,
                  icon: const Icon(AppIcons.home),
                  label: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
