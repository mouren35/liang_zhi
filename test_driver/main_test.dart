import 'package:flutter_driver/driver_extension.dart';
import 'package:liangzhi/main.dart' as application;

Future<void> main() {
  enableFlutterDriverExtension();
  return application.main();
}
