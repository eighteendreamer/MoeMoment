# MoeMoment 美瞳管理

本地优先的美瞳管理应用。原 Flutter 版本的技术栈替换为 **Rust + Tauri 2 + SeaORM + React + Arc UI + SQLite**，
业务需求、页面结构和数据规则沿用 `../meitong_app_development_prompt.md`。

当前工程位于 `rust_dev/`，是独立可运行的应用（不是对 Flutter 目录的改造）。

## 1. 技术栈

| 层次 | 选型 | 版本 |
| --- | --- | --- |
| 应用框架 | Tauri | 2.12.7 |
| 后端语言 | Rust | 1.96（edition 2024） |
| ORM / 迁移 | SeaORM + sea-orm-migration（SQLite 驱动 sqlx-sqlite） | 2.0.4 |
| 数据库 | SQLite（WAL、外键约束开启） | 随系统 |
| 前端 | React + TypeScript + Vite | 19.3 / 7.0 / 8.3 |
| UI 组件 | Arc UI（https://uiarc.dev，CSS Modules + 语义 token） | shadcn registry 安装 |
| 其它 | chrono（日期）、reqwest（更新检查）、sha2（校验）、tauri-plugin-notification | — |
| 原生提醒 | Android：Kotlin 插件 + AlarmManager + BroadcastReceiver；桌面 / iOS：前台轮询 | — |

Arc UI 通过 `npx shadcn@latest add @uiarc/...` 安装到 `src/components/arc/`，源码属于本项目，可直接改：

- `src/components/arc/button/button.module.css`：主按钮改为品牌主色（原为中性墨色）
- `src/components/arc/date-picker/date-picker.tsx`：底部操作与占位文案中文化

## 2. 目录结构

```text
rust_dev/
├── index.html
├── package.json
├── vite.config.ts
├── src/                        # 前端（React）
│   ├── main.tsx                # 入口：先加载 Arc foundation.css，再加载主题
│   ├── App.tsx                 # 页面分发
│   ├── app/navigation.tsx      # 轻量导航栈（两个主 Tab + 二级页面）
│   ├── components/
│   │   ├── Page.tsx            # 页面外壳：标题、滚动区、底部导航
│   │   ├── LensRow.tsx         # 美瞳列表行 + 状态标签
│   │   ├── ConfirmDialog.tsx   # 二次确认（删除 / 丢弃）
│   │   └── arc/                # Arc UI 组件源码
│   ├── features/
│   │   ├── home/HomePage.tsx            # 首页：即将到期 / 我的美瞳 / 统计 / 列表
│   │   ├── lens/LensDetailPage.tsx      # 详情、开封、丢弃、删除、照片预览
│   │   ├── lens/LensFormPage.tsx        # 新增 / 编辑、图片上传、镜片参数
│   │   ├── lens/ExpiringPage.tsx        # 到期美瞳列表
│   │   └── settings/                    # 我的、系统通知、提醒设置、护理液、周期、更新
│   ├── lib/                    # types.ts / api.ts / format.ts
│   └── styles/app.css          # 粉色主题 token 与页面样式
├── scripts/cdp.mjs             # 开发期截图 / 调试辅助（不参与打包）
├── scripts/make-icon.mjs       # 兜底图标生成器（正式图标使用 src-tauri/icons/logo.jpg）
└── src-tauri/                  # 后端（Rust）
    ├── Cargo.toml
    ├── tauri.conf.json
    ├── capabilities/default.json
    └── src/
        ├── lib.rs              # 启动：DB、图片目录、通知、命令注册
        ├── error.rs            # 统一错误（序列化为中文字符串）
        ├── dto.rs              # 前后端契约（camelCase）
        ├── db/
        │   ├── mod.rs          # 连接（WAL、外键）、迁移、幂等种子
        │   ├── entities/       # 10 张表的 SeaORM 实体
        │   ├── migrations/     # 版本化迁移器
        │   └── sql/001_init.sql
        ├── domain/
        │   ├── dates.rs        # 周期推进、本地日期、时间校验
        │   └── lens.rs         # 到期/状态推导、护理液到期、下次更换
        ├── services/           # lens / cycle / care / settings / notification / media / updater
        │   └── reminder_mobile.rs  # Android 原生闹钟桥接
        └── commands/           # Tauri 命令（薄封装）
```

## 3. 数据库

迁移版本 `m20260101_000001_init`，DDL 见 `src-tauri/src/db/sql/001_init.sql`，10 张表：

| 表 | 说明 | 关键约束 |
| --- | --- | --- |
| `lens_cycles` | 周期（内置 + 自定义） | `(cycle_name, cycle_unit, cycle_value)` 唯一 |
| `lenses` | 美瞳主表 | `cycle_id → lens_cycles(id)`，`ON DELETE RESTRICT` |
| `lens_images` | 多图 | `lens_id → lenses(id)`，`ON DELETE CASCADE` |
| `lens_expiry_reminder_settings` | 美瞳到期提醒（单例 id=1） | 默认开启、提前 3 天、09:00 |
| `care_solution_change_reminders` | 护理液更换提醒（单例） | 默认每 3 天、09:00 |
| `care_solution_change_logs` | 更换历史 | `reminder_id → care_solution_change_reminders(id)` CASCADE |
| `care_solution_bottles` | 护理液信息 | 仅一条 `is_current = 1` |
| `care_solution_expiry_settings` | 护理液到期提醒（单例） | 默认开启、提前 3 天 |
| `app_settings` | Key-Value 设置 | `key` 主键 |
| `notification_logs` | 通知计划与发送记录 | `notification_key` 唯一（去重） |

- 连接级开启 `foreign_keys`、`journal_mode=WAL`、`busy_timeout`；
- 索引覆盖外键字段、`status`、`package_expiry_date`、`opened_at`、`updated_at`、通知计划日期；
- 种子数据使用 `INSERT OR IGNORE`，重复启动不会覆盖用户配置（有测试覆盖）；
- 迁移只做增量，不删库重建；结构变更请新增迁移文件并在 `Migrator::migrations()` 注册。

## 4. 关键业务规则

**状态**

- 持久化状态：`unopened` / `opened` / `discarded`；
- `expired` 由日期实时推导，不写库；到期日当天即视为过期（`today >= expiry_date`）；
- 已丢弃记录不参与「使用中 / 未开封 / 已过期」统计，也不再安排提醒。

**到期日**

- 未开封：只看包装有效期，未填写则不推断；
- 已开封：`开封日 + 周期` 与包装有效期同时存在时取较早者（`expiry_source` 说明来源）；
- 月、年按自然日历推进，月末/闰年截断（`chrono` 的 `Months` 语义），测试覆盖 1 月 31 日 + 1 月、闰年 2 月 29 日 + 1 年。

**统计**

- 由查询结果实时计算，不落库；`discarded` 单独计数，不计入在册总数。

**提醒**

- 三类提醒独立配置、独立计算、独立通知；
- 通知计划写入 `notification_logs`，`notification_key = 类型:目标id:计划日期`，唯一索引保证不重复；
- 数据变更（新增/编辑/开封/丢弃/删除/护理液日期变化/提醒配置变化）后自动重排计划；
- **Android**：重排时把未来计划交给系统闹钟（`ReminderPlugin` → `AlarmManager.setExactAndAllowWhileIdle`），
  应用被关闭也能触发；计划同时写入 SharedPreferences，由 `BootReceiver` 在设备重启 / 应用更新后恢复。
  已交给系统的条目在前台轮询里会被跳过，避免重复通知；没有「精确闹钟」权限时自动降级为非精确调度。
- **桌面 / iOS**：应用运行期间每分钟检查，启动与回到前台时补发。

**视觉与素材**

- 应用图标来自 `src-tauri/icons/logo.jpg`，用 `npx tauri icon` 生成全平台图标（含 Android 自适应图标）；
- Android 主题固定浅色：状态栏 / 导航栏取 `#FFF7FA`，启动背景同色，避免白闪与深色模式刷黑；
- 图片在选择后由 `src/lib/image.ts` 压缩（最长边 1600、JPEG 0.85），再交给 Rust 落盘；
- 移动端安全区在原生侧处理（`MainActivity` 用 `WindowInsets` 给内容让出系统栏与刘海），
  Web 层仍保留 `env(safe-area-inset-*)` 供 iOS 使用。

**更新**

- 更新模块独立于业务，`src-tauri/src/services/updater.rs`；
- 支持官方源 / 镜像源 / 自动回退，镜像地址为白名单常量（未配置时明确报错，不臆造地址）；
- 下载后计算 SHA-256；Release 附带校验文件（含 `sha256` / `checksum` 命名的资源）时自动下载并比对，不一致直接删除文件；
- 只允许 HTTPS 下载；各平台只提供该平台允许的安装引导。

## 5. 运行与构建

```bash
cd rust_dev
npm install
npm run tauri dev          # 开发（桌面窗口 430×900，便于按移动端预览）
npm run build              # 前端类型检查 + 构建
npm run tauri build        # 桌面发行包

cargo test --manifest-path src-tauri/Cargo.toml   # Rust 单元 + 迁移集成测试
```

Android（Windows 上已验证可编译）：

```bash
export ANDROID_HOME="$LOCALAPPDATA/Android/Sdk"
export NDK_HOME="$ANDROID_HOME/ndk/28.2.13676358"
npx tauri android init                    # 生成 src-tauri/gen/android
npx tauri android build --debug --apk     # 产出 debug APK（四 ABI 通用包，体积很大）
npx tauri android build --apk             # 发布包，建议配合 --target aarch64 单独构建
npx tauri android dev                     # 需要连接真机或模拟器
```

iOS：Tauri 要求 macOS + Xcode，Windows 无法本地编译。工程已按 Tauri 2 移动端组织，
在 macOS 上执行 `npx tauri ios init` / `npx tauri ios build` 即可；签名与 TestFlight 分发需 Apple 账号。

### 开发期截图（可选）

```bash
# 启动时打开 WebView2 调试端口
WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS="--remote-debugging-port=9222" npx tauri dev
node scripts/cdp.mjs shot .screenshots/home.png
node scripts/cdp.mjs eval "const m = await import('/src/lib/api.ts'); return await m.api.listCycles();"
```

## 6. 实际验证结果

| 检查 | 结果 |
| --- | --- |
| `cargo test` | 24 个测试全部通过（日期、周期、状态、护理液、版本比较、迁移 + 种子幂等 + 外键约束） |
| `npm run build`（tsc + vite） | 通过 |
| 桌面运行（WebView2） | 启动成功，数据库写入 `%APPDATA%\com.moemoment.app\moemoment.sqlite3` |
| 界面验证 | 首页 / 详情 / 表单 / 到期列表 / 我的 / 提醒设置 / 护理液 / 通知记录 / 自动更新，均截图确认 |
| 业务流程 | 新增（6 项镜片参数按原键名存 JSON）、编辑、开封（年抛 + 包装有效期取较早者）、丢弃、删除、自定义周期增删、内置周期删除被拦截、图片上传落盘 / 删除记录后文件被清理 |
| 通知（桌面） | 计划生成、去重、按时间补发（桌面端实发通知）、记录状态更新 |
| 图片压缩 | 用 8.2 MB / 1800×1400 的测试图走完整流程：压缩后 1.2 MB 落盘为 `.jpg`，记录关联正常，删除记录后文件被清理 |
| 图标 | 用 `logo.jpg` 生成全平台图标；APK 内确认 `mipmap-anydpi-v26/ic_launcher.xml` 自适应图标生效 |
| Android | `npm run tauri android build -- --debug --apk` 构建成功，产物 `src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk`（debug 四 ABI + 符号，体积很大；发布请用 release 并按 ABI 拆分） |
| Android 原生提醒 | APK 内已确认：`ReminderPlugin` 打入 dex，`ReminderReceiver` / `BootReceiver` 注册在清单，`POST_NOTIFICATIONS` / `SCHEDULE_EXACT_ALARM` / `RECEIVE_BOOT_COMPLETED` 权限就位。**运行时行为未验证**（本机没有模拟器、也没有连接设备） |

## 7. 平台限制与已知边界

- **后台定时通知**：Android 已接入系统闹钟（`gen/android/.../ReminderPlugin.kt` + `ReminderStore.kt`），
  关闭应用后仍能触发，重启后由 `BootReceiver` 恢复。两点限制：
  1. 未授予「精确闹钟」权限（Android 12+ 需用户在系统设置允许）时降级为非精确调度，触发时间可能浮动几分钟；
  2. `notification_logs` 的状态不会因系统闹钟触发而回写（BroadcastReceiver 不直接写 SQLite），
     界面上的「待触发」表示已交给系统；下次启动重排时旧计划会被替换。
     iOS 侧仍是前台轮询 + 恢复补发，要精确后台提醒需在 macOS 上接 UNUserNotificationCenter。
- **Android 音频/振动**：通知渠道使用默认重要性 HIGH，未做自定义铃声与免打扰适配。
- **图片选择**：使用 WebView 的 `<input type="file" accept="image/*">`，桌面与移动端都由系统选择器接管；
  没有额外集成原生相册插件。图片复制到应用数据目录 `images/`，数据库只存绝对路径。
- **iOS 更新**：按 Apple 规则只能引导到 App Store / TestFlight，不实现 IPA 自安装。
- **自动更新**：仓库信息与镜像地址为占位配置，未填写前「检查更新」会提示配置缺失。

## 8. 需要补充的配置

1. `src-tauri/src/services/updater.rs`
   - `GITHUB_OWNER` / `GITHUB_REPO`：Release 所在仓库；
   - `MIRROR_BASES`：可信镜像白名单，例如 `&["https://your-mirror.example.com/"]`；留空则只能用官方源。
2. Release 资源命名：Android 为 `*.apk`，Windows 为 `*.msi` / `*.exe`，macOS 为 `*.dmg`；
   建议同时上传 `SHA256SUMS.txt`（每行 `<hash>  <文件名>`）以启用下载校验。
3. Android 签名：`src-tauri/gen/android/app/build.gradle.kts` 中配置 `signingConfigs`，
   keystore 与密码不要提交到仓库。
4. `tauri.conf.json` 的 `identifier` 当前为 `com.moemoment.app`，发布前按需调整（改变后会切换数据目录）。

## 9. 设计决策

- **状态/统计不落库**：数据库只存事实，派生值统一由 `domain::lens` 计算，避免过期判断出现两套真相。
- **日期用字符串存 `YYYY-MM-DD`**：本地日历日期，避免 UTC 转换导致的偏移；时间戳用 RFC3339。
- **图片存绝对路径**：路径来自应用数据目录，删除前校验目标必须位于 `images/` 内，避免误删相册原图。
- **通知不在事务内发送**：先提交数据，再重排通知；通知失败只记日志，不回滚业务数据。
- **导航不引入路由库**：两个主 Tab + 栈式二级页面，避免移动端 URL / 历史栈不一致。
- **Arc UI 只做组件基座**：列表、统计、设置行等布局用项目自己的 CSS，保证粉色设计 token 统一。
