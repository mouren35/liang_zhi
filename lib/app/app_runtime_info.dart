import 'package:liangzhi/app/app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

final class AppRuntimeInfo {
  const AppRuntimeInfo({
    required this.name,
    required this.version,
    required this.buildNumber,
  });

  static const AppRuntimeInfo fallback = AppRuntimeInfo(
    name: AppInfo.name,
    version: AppInfo.version,
    buildNumber: AppInfo.buildNumber,
  );

  final String name;
  final String version;
  final String buildNumber;

  static Future<AppRuntimeInfo> load() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return AppRuntimeInfo(
      name: packageInfo.appName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}
