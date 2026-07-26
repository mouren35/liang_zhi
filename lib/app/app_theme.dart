import 'package:flutter/material.dart';
import 'package:liangzhi/shared/design/app_colors.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/design/app_typography.dart';

abstract final class AppTheme {
  static ThemeData light(TargetPlatform platform) {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.successSoft,
      onPrimaryContainer: AppColors.accentDark,
      secondary: AppColors.accentDark,
      onSecondary: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.surface,
      outline: AppColors.divider,
    );

    final TextTheme textTheme = AppTypography.textTheme(platform);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      dividerColor: AppColors.divider,
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.divider),
          borderRadius: AppRadii.card,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.minimumTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.minimumTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          side: const BorderSide(color: AppColors.accent),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWarm,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
          borderRadius: AppRadii.input,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
          borderRadius: AppRadii.input,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.successSoft,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((Set<WidgetState> states) {
          return AppTypography.statusLabel.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.textSecondary,
          );
        }),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: AppColors.surface),
      ),
    );
  }
}
