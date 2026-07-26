import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';

void main() {
  test('间距等级严格递增', () {
    expect(
      <double>[
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ],
      orderedEquals(<double>[4, 8, 12, 16, 24, 32, 48]),
    );
  });

  test('触控目标满足 48 像素基线', () {
    expect(AppDimensions.minimumTouchTarget, greaterThanOrEqualTo(48));
  });
}
