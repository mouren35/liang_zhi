import 'package:flutter/material.dart';
import 'package:liangzhi/shared/design/app_colors.dart';

abstract final class AppTypography {
  static const TextStyle pageTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle foodName = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle supporting = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle statusLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextTheme textTheme(TargetPlatform platform) {
    final String? fontFamily = platform == TargetPlatform.iOS ? 'PingFang SC' : null;
    return const TextTheme(
      headlineMedium: pageTitle,
      titleLarge: sectionTitle,
      titleMedium: foodName,
      bodyMedium: body,
      bodySmall: supporting,
      labelSmall: statusLabel,
      labelLarge: button,
    ).apply(fontFamily: fontFamily);
  }
}
