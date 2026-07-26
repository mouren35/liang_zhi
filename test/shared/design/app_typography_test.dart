import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/design/app_typography.dart';

void main() {
  test('文本层级映射完整', () {
    final TextTheme theme = AppTypography.textTheme(TargetPlatform.android);

    expect(theme.headlineMedium?.fontSize, 24);
    expect(theme.titleLarge?.fontSize, 17);
    expect(theme.titleMedium?.fontSize, 15);
    expect(theme.bodyMedium?.fontSize, 14);
    expect(theme.bodySmall?.fontSize, 12);
    expect(theme.labelSmall?.fontSize, 11);
    expect(theme.labelLarge?.fontSize, 15);
  });

  test('iOS 优先使用 PingFang SC', () {
    final TextTheme theme = AppTypography.textTheme(TargetPlatform.iOS);

    expect(theme.bodyMedium?.fontFamily, 'PingFang SC');
  });
}
