import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/app/app_runtime_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('从安装包元数据读取应用名、版本号和构建号', () async {
    PackageInfo.setMockInitialValues(
      appName: '粮知',
      packageName: 'com.liangzhi.app',
      version: '0.1.0',
      buildNumber: '7',
      buildSignature: '',
    );

    final AppRuntimeInfo info = await AppRuntimeInfo.load();

    expect(info.name, '粮知');
    expect(info.version, '0.1.0');
    expect(info.buildNumber, '7');
  });
}
