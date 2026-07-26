import 'package:flutter/material.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppDimensions.readableContentMaxWidth),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
