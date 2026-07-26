# 粮知技术栈

- Flutter 3.41.6 / Dart 3.11.4；
- Riverpod：依赖注入与状态管理，不使用 Riverpod 代码生成；
- go_router：五项底部导航与子路由；
- Drift + SQLite：食品、分类、位置与条码商品缓存；
- build_runner + Drift 生成器：数据库代码生成；
- SharedPreferences：首次启动、列表偏好和通知设置；
- mobile_scanner：通过格式白名单扫描 EAN-8、EAN-13、UPC-A、UPC-E、Code 128；
- package:http：使用可注入的 `Client` 调用 Open Food Facts v3.6 只读商品查询；
- flutter_local_notifications + timezone：临期、今日到期、已过期汇总、长期未更新；
- clock（开发依赖）：为日期规则和通知调度测试提供可控时间源；
- GitHub Actions：Linux 分析/测试/Android 构建，macOS iOS 无签名构建。

环境通过 `--dart-define=APP_ENV=development|test|production` 区分，共用包标识 `com.liangzhi.app`，不建立原生 Flavor。依赖在实施时选择与当前 Flutter SDK 兼容的版本，并将解析结果锁定在 `pubspec.lock`。
