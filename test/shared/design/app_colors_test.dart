import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/shared/design/app_colors.dart';

void main() {
  test('颜色角色与视觉基线一致', () {
    expect(AppColors.accent.toARGB32(), 0xFF3F854C);
    expect(AppColors.accentDark.toARGB32(), 0xFF2F6E3C);
    expect(AppColors.surface.toARGB32(), 0xFFFFFFFF);
    expect(AppColors.surfaceWarm.toARGB32(), 0xFFF7F6F2);
    expect(AppColors.textPrimary.toARGB32(), 0xFF191B18);
    expect(AppColors.textSecondary.toARGB32(), 0xFF777B75);
    expect(AppColors.divider.toARGB32(), 0xFFE8E9E5);
    expect(AppColors.successSoft.toARGB32(), 0xFFEDF5EE);
    expect(AppColors.expiring.toARGB32(), 0xFFFFB547);
    expect(AppColors.error.toARGB32(), 0xFFF02D23);
  });
}
