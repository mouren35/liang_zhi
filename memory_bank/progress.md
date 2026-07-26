# 粮知 V0.1.0 实施进度

> 最后更新：2026-07-26
> 当前分支：`mouren35/v0.1.0`
> 目标标签：`v0.1.0`

## 1. 当前状态

当前已完成现有工程与本机工具链核验，开始 V0.1.0 工程基础实施。

已确认范围：

- 原地演进现有 Flutter 工程，不重新创建项目；
- 正式名称为“粮知”，包标识为 `com.liangzhi.app`；
- 实施基础应用、手动添加、一维条形码扫码、Open Food Facts 查询与四类本地通知；
- 五项导航：首页、到期提醒、扫码添加、全部食物、我的；
- Android 本地完成，iOS 使用 macOS CI 无签名构建；
- iOS 真机、签名和 TestFlight 依赖外部 Mac、设备与凭据；
- 通过验收后创建 `v0.1.0` 标签。

## 2. 既有提交映射

既有工作引用真实历史提交，不补造或拆分历史：

| 提交 | 已有内容 | 对应计划状态 |
| --- | --- | --- |
| `6c59475` | 创建 `liangzhi` Flutter 工程及 Android/iOS 平台目录 | 步骤 1 部分完成，仍需重新验证 Android 启动和 iOS CI |
| `e79eca0` | 忽略本地代理技能目录 | 工程维护项，非业务步骤 |
| `d1ac379` | 增加贡献指南与初始技术栈说明 | 文档基础，已在当前基线中扩充 |
| `23f75e9` | 增加 AGENTS.md 代理规则 | 开发约束已生效 |

后续每个提交必须对应一个可独立验证的逻辑步骤；不要求为已经存在的步骤补造提交。

## 3. 里程碑

| 里程碑 | 状态 | 验证 |
| --- | --- | --- |
| M0：需求澄清 | 已完成 | 产品名、范围、标识、导航、扫码、通知、UI 和验收约束已确认 |
| M1：架构与完整 Schema | 已完成，待提交 | `architecture.md` 已包含数据库、远程查询、通知、隐私与测试架构 |
| M2：工程与 CI 基础 | 未开始 | 按实施计划步骤 1—15 执行 |
| M3：本地数据与手动闭环 | 未开始 | 按步骤 16—77 执行 |
| M4：条形码扫码 | 未开始 | 按步骤 78—85 执行 |
| M5：本地通知 | 未开始 | 按步骤 86—91 执行 |
| M6：构建、验收与冻结 | 未开始 | 按步骤 92—102 执行 |

## 4. 当前环境事实

- Flutter 3.41.6 stable；
- Dart 3.11.4；
- Windows 10；
- Android SDK 36.1.0，Android 工具链可用；
- 已配置 `Small_Phone` Android 模拟器；
- 当前没有连接 Android/iOS 移动设备；
- Windows 无法本地构建 iOS，必须依赖 macOS CI 或外部 Mac。

## 5. 实施记录

### 步骤 1：核验现有 Flutter 项目

- 提交：本步骤提交；
- 修改文件：`memory_bank/progress.md`；
- 实际验证：`flutter doctor -v`、检查平台目录、检查当前分支与 Git 状态；
- 结果：Flutter 3.41.6、Dart 3.11.4、Android SDK 36.1.0 可用；Android/iOS 平台目录存在且未重新生成工程；
- 未解决问题：当前未连接 Android 设备；iOS 构建、真机、签名与 TestFlight 依赖 macOS/外部环境；
- 下一步骤：步骤 2，配置应用显示名称。

### 步骤 2：配置应用显示名称

- 提交：本步骤提交；
- 修改文件：Android Manifest、iOS Info.plist、`memory_bank/progress.md`；
- 实际验证：检查 Android `android:label` 与 iOS `CFBundleDisplayName`/`CFBundleName`；
- 结果：双端显示名称均为“粮知”；
- 未解决问题：启动器与 iOS 主屏幕视觉确认分别等待 Android 设备和外部 iOS 环境；
- 下一步骤：步骤 3，配置应用包标识。

### 步骤 3：配置应用包标识

- 提交：本步骤提交；
- 修改文件：Android Gradle、MainActivity、iOS Xcode 工程、`memory_bank/progress.md`；
- 实际验证：全仓搜索旧标识并核对 Android namespace/application ID、iOS App/Test 标识；
- 结果：应用标识统一为 `com.liangzhi.app`，测试 Target 为 `com.liangzhi.app.RunnerTests`；
- 未解决问题：iOS 构建验证依赖 macOS CI；
- 下一步骤：步骤 4，清理默认示例内容。

### 步骤 4：清理默认示例内容

- 提交：本步骤提交；
- 修改文件：`lib/main.dart`、`test/widget_test.dart`、`memory_bank/progress.md`；
- 实际验证：搜索默认计数器标识并运行占位首页组件测试；
- 结果：默认计数器、按钮和示例注释已移除，仅保留“粮知”占位首页；
- 未解决问题：无；
- 下一步骤：步骤 5，建立基础依赖清单。

### 步骤 5：建立基础依赖清单

- 提交：本步骤提交；
- 修改文件：`pubspec.yaml`、`pubspec.lock`、`memory_bank/progress.md`；
- 实际验证：使用 Flutter Pub 解析运行与开发依赖，并检查依赖清单；
- 结果：Riverpod、go_router、Drift/SQLite、设置、扫码、HTTP、通知、时区、生成器、Clock 与集成测试依赖解析成功；
- 未解决问题：无；
- 下一步骤：步骤 6，启用统一静态检查规则。

## 6. 外部阻塞与发布前事项

- iOS 真机、签名和 TestFlight 需要外部 Mac、Apple 设备及签名凭据；
- 正式发布前需完成 Open Food Facts API 使用登记；
- Open Food Facts 对中国商品的覆盖不保证，未命中和网络失败必须始终可手动补充；
- 当前尚未创建 `v0.1.0` 标签；
- 当前文档改动尚未提交，不能将“待提交”状态报告为已冻结版本。

## 7. 每步记录模板

每完成一个实施步骤，在本文件追加：

```text
步骤编号与名称：
提交：
修改文件：
实际验证：
结果：
未解决问题：
下一步骤：
```
