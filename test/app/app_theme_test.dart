import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/app_theme.dart';
import 'package:liangzhi/shared/design/app_colors.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';

void main() {
  test('浅色主题统一主要组件样式', () {
    final ThemeData theme = AppTheme.light(TargetPlatform.android);

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppColors.accent);
    expect(theme.scaffoldBackgroundColor, AppColors.surface);
    expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.inputDecorationTheme.fillColor, AppColors.surfaceWarm);
    expect(theme.navigationBarTheme.indicatorColor, AppColors.successSoft);

    final ButtonStyle? buttonStyle = theme.filledButtonTheme.style;
    final Size? minimumSize = buttonStyle?.minimumSize?.resolve(<WidgetState>{});
    expect(minimumSize?.height, AppDimensions.minimumTouchTarget);
  });
}
