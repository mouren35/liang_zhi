# 粮知

粮知是一款本地优先的家庭食物库存与到期提醒 Flutter 应用。V0.1.0 支持 Android 和
iOS，包含手动录入、一维条形码扫码、Open Food Facts 只读查询、本地通知和安全清除数据。

## 工程结构

- `lib/app/`：应用启动、环境、路由和主题；
- `lib/core/`：数据库、设置、网络、通知、文件与统一错误；
- `lib/features/`：按首页、到期提醒、扫码、库存、添加、详情和“我的”组织的功能代码；
- `lib/shared/`：领域模型、设计令牌和跨功能组件；
- `test/`：镜像 `lib/` 结构的单元与组件测试；
- `integration_test/`：端到端流程测试。

依赖方向固定为“页面 → Provider/控制器 → Repository 接口 → 数据库/网络/平台服务”。
页面不得直接访问 Drift、HTTP 或平台插件，`core` 不得依赖具体功能页面。

## 命名规范

- Dart 文件使用 `lower_snake_case.dart`；
- 类型、枚举和 Widget 使用 `UpperCamelCase`；
- 变量、参数和方法使用 `lowerCamelCase`；
- Riverpod Provider 统一使用 `Provider` 后缀；
- 页面文件使用 `_page.dart` 后缀；
- 通用组件使用 `_widget.dart` 后缀，业务组件使用明确业务名称；
- Drift 表、SQLite 字段和领域模型保持同一业务词汇，数据库字段使用 `snake_case`；
- 测试文件镜像源文件路径并使用 `_test.dart` 后缀。

## 本地开发

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run --dart-define=APP_ENV=development
```

每次提交前必须依次执行依赖获取、格式检查、静态分析和全部自动化测试。Linux CI 还会构建
Android 调试 APK，macOS CI 会执行 iOS 无签名构建。

Open Food Facts 基地址可通过
`--dart-define=OPEN_FOOD_FACTS_BASE_URL=https://world.openfoodfacts.org` 覆盖。

## 隐私边界

食品库存、数量、生产日期和到期日期仅保存在设备本地。联网仅用于向配置的 Open Food
Facts HTTPS 服务查询用户扫描的一维条形码以及加载用户确认的远程商品图片。

完整产品与架构基线见 [PRD](memory_bank/prd.md)、
[架构说明](memory_bank/architecture.md) 和
[实施计划](memory_bank/implementation_plan.md)。
