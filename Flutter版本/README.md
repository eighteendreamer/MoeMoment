# MoeMoment（美瞳管理 App）

本地优先的美瞳管理应用：记录、管理、提醒你的每一副美瞳。基于 **Flutter + ForUI + SQLite (Drift)**，支持 **Windows 桌面 + Android + iOS**，采用响应式布局。

## 功能概览

- **首页**：即将到期 → 我的美瞳 → 美瞳统计（使用中 / 未开封 / 已过期）→ 美瞳列表（搜索、周期筛选、状态筛选、悬浮「+」新增）。底部仅「首页」「我的」两个主 Tab。
- **美瞳管理**：品牌 / 名称 / 周期 / 颜色方案 / 镜片参数（Lens_Specs JSON）/ 备注 / 多张照片；开封、丢弃、删除、编辑；多图持久化（复制到 App 目录）。
- **周期**：内置日抛、双周抛、月抛、季抛、半年抛、年抛；支持自定义周期（day / week / month / year + 正整数），到期日按自然日历计算（月末、闰年截断）。
- **护理液**：护理液信息维护（品牌、开封日期、包装有效期、开封后有效天数）、更换记录（同一事务写历史 + 更新下次日期）。
- **三类独立提醒**：美瞳到期提醒、护理液更换提醒、护理液到期提醒。独立开关、提前天数、提醒时间；本地通知调度、取消与 `notification_key` 去重。
- **自动更新**（Android）：GitHub Releases 检查、版本比较、官方源 / 镜像源 / 自动（镜像失败回退官方）、下载进度、SHA-256 校验、交由系统安装器安装。iOS 引导至 App Store / TestFlight（普通 App 不支持应用内自更新）。
- **响应式布局**：内容区限宽（720）居中，适配平板与宽屏；安全区域、键盘弹出、小屏与长列表已适配。

## 环境要求

- Flutter 3.47+ / Dart 3.13+
- Android：Android SDK Platform 37（`flutter_local_notifications` 与 `permission_handler` 要求 compileSdk 37）、JDK 17、核心库脱糖已启用
- Gradle 发行包使用腾讯镜像（`android/gradle-wrapper.properties`）；Maven 依赖配置了阿里云镜像（`android/settings.gradle.kts`、`android/build.gradle.kts`），失败自动回退官方源
- 国内网络环境建议为 Gradle 配置代理（`~/.gradle/gradle.properties` 的 `systemProp.https.proxyHost/Port`，该文件在本机、不入库）
- iOS：macOS + Xcode（本仓库代码含完整 iOS 工程，但 Windows 环境无法编译验证 iOS）

## 常用命令

```bash
flutter pub get                                # 安装依赖
dart run build_runner build --delete-conflicting-outputs   # Drift 代码生成
flutter analyze                                # 静态分析
dart format lib test                           # 格式化
flutter test                                   # 运行全部测试
flutter run -d <设备ID>                        # 运行到设备
flutter build apk --debug                      # Android debug 构建
flutter build apk --release                    # Android release 构建（需签名配置）
```

## 项目结构

```text
lib/
├── main.dart                    # 入口：初始化数据库、通知，启动时恢复提醒计划
├── app/
│   ├── app.dart                 # MaterialApp + ForUI 主题
│   ├── app_services.dart        # 服务容器（Provider 注入）
│   ├── router.dart              # go_router：两 Tab Shell + 二级页面
│   └── theme/app_theme.dart     # 淡粉色设计 token（主色 #E9789A）
├── core/
│   ├── database/                # Drift：10 张表、种子数据、schemaVersion、外键
│   ├── notifications/           # 本地通知：权限、调度、取消、去重、通知日志
│   ├── storage/image_storage.dart  # 图片复制到持久化目录、按归属清理
│   └── date/date_service.dart   # 日期计算服务（到期日 / 提醒日 / 剩余天数）
├── features/
│   ├── home/                    # 首页、到期列表
│   ├── lens/                    # 美瞳仓库、业务规则、详情、添加编辑
│   ├── care_solution/           # 护理液信息与更换事务
│   ├── reminder/                # 三类提醒设置页、统一重排调度器
│   ├── settings/                # 「我的」、系统通知
│   └── updater/                 # GitHub 更新（待配置）、更新页
└── shared/widgets/              # 响应式容器、状态标签、空状态等
```

## 数据库

10 张表：`lens_cycles`、`lenses`、`lens_images`、`lens_expiry_reminder_settings`、
`care_solution_change_reminders`、`care_solution_change_logs`、`care_solution_bottles`、
`care_solution_expiry_settings`、`app_settings`、`notification_logs`。

- 启用外键约束；`lenses.cycle_id` 删除策略 `RESTRICT`，美瞳删除级联删除图片记录。
- 业务日期以 TEXT（`yyyy-MM-dd`）存储，与时间戳字段（createdAt / updatedAt）区分，避免时区偏移。
- `schemaVersion = 1`；后续结构变更必须新增迁移，禁止删库重建。
- 内置周期与默认提醒配置初始化幂等，不覆盖用户配置。

## 关键业务规则

- 持久化状态仅 `unopened` / `opened` / `discarded`；**已过期由日期动态推导**（`today >= expiryDate` 即过期），不写入数据库。
- 已开封到期日 = 开封日期 + 周期，与包装有效期取较早者；未开封按包装有效期（未填写时不推断）。
- 月 / 年按自然日历计算，月末与闰年截断（1 月 31 日 + 1 月 = 2 月最后一天；闰年 2 月 29 日 + 1 年 = 2 月 28 日）。
- Lens_Specs JSON 键名保持需求约定拼写（`Lens_diameter`、`Colored_diameter`、`Moisture_content`、`Base_arc`、`Left_eye_prescription`、`right_eye_prescription`），允许缺失，含水量存 `48` 展示 `48%`。
- 通知仅在数据库提交后调度；关闭总开关取消全部待触发提醒；启动 / 恢复前台时全量校验重排。

## 设计决策与待配置项

| 项目 | 状态 | 说明 |
|---|---|---|
| GitHub owner / repo | **待配置** | 编辑 `lib/features/updater/github_config.dart` 填写真实仓库 |
| 镜像白名单 | **待配置** | 同上，`mirrorWhitelist` 只接受包含 `{tag}`、`{asset}` 的可信模板 |
| iOS 分发渠道 | **待配置** | `iosStoreUrl` 填 App Store / TestFlight 链接 |
| Android 签名 | **待配置** | release 构建需自行配置 keystore（不要提交签名文件） |
| 提醒时间选项 | 内置 08:00 / 09:00 / 20:00 | 如需任意时间可扩展时间选择器 |
| 状态管理 | provider + Drift 响应式流 | 轻量方案，未引入第二套状态库 |
| 通知精确闹钟 | 未申请 | 使用 `inexactAllowWhileIdle`，不承诺精确到秒的触发 |

## 平台支持与验证状态

- **Windows 桌面**：✅ 已构建并通过实机启动验证（窗口渲染、首页四区块、底部双 Tab、响应式居中布局、SQLite 数据落盘均正常）。`flutter run -d windows` 或直接运行 `build\windows\x64\runner\Debug\moe_moment.exe`。
- **Android**：✅ release APK 已构建（debug 签名，可直接安装体验）；正式发布前需配置 release 签名。真机运行时行为（通知送达、相册选择）需真机验证。
- **iOS**：✅ 通过 GitHub Actions（macOS runner）云端编译产出**未签名 IPA**（`.github/workflows/ios-build.yml`，push 到 main 或手动触发）。未签名 IPA 需经 Sideloadly / AltStore 侧载，或用 Apple 开发者证书签名 / 提交 TestFlight 后才能安装到设备。Windows 本机无法编译 iOS。

### 产物位置

| 平台 | 命令 | 产物 |
|---|---|---|
| Windows | `flutter build windows` | `build\windows\x64\runner\Release\moe_moment.exe`（整目录分发） |
| Android | `flutter build apk --release` | `build\app\outputs\flutter-apk\app-release.apk` |
| iOS | push 到 main 或手动触发 GitHub Actions | Actions 产物 `moe-moment-ios-unsigned`（未签名 IPA） |

### 质量验证

`flutter analyze` 无问题；`flutter test` 61 个用例全部通过（日期边界、数据库事务、外键、统计口径、JSON 契约、版本比较、镜像白名单、首页 Widget）；Windows 实机启动 + 截屏验证通过。

## 隐私

所有数据仅保存在设备本地。不内置任何 GitHub Token、签名密钥或凭据；日志不记录处方等敏感个人信息。
