import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/care_solution.dart';
import 'tables/lens_cycles.dart';
import 'tables/lens_images.dart';
import 'tables/lenses.dart';
import 'tables/settings_and_logs.dart';

part 'app_database.g.dart';

/// 应用数据库。
///
/// - 启用 SQLite 外键约束。
/// - 初始化内置周期与默认提醒配置，可重复执行，不覆盖用户已有配置。
/// - 结构变更时提升 [schemaVersion] 并编写迁移，禁止删库重建。
@DriftDatabase(
  tables: [
    LensCycles,
    Lenses,
    LensImages,
    LensExpiryReminderSettings,
    CareSolutionChangeReminders,
    CareSolutionChangeLogs,
    CareSolutionBottles,
    CareSolutionExpirySettings,
    AppSettings,
    NotificationLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  /// 显式定位并创建数据库目录后再打开。
  ///
  /// Windows 上默认数据目录可能不存在，直接打开会触发 sqlite disk I/O 错误；
  /// 平台差异收敛在此处，各端统一使用应用支持目录。
  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      final file = File('${dir.path}${Platform.pathSeparator}moe_moment.sqlite');
      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _seedBuiltinData();
    },
  );

  /// 初始化内置周期和默认提醒设置。
  ///
  /// 使用 insertOrIgnore 保证幂等：已存在的记录（含用户修改后的配置）不会被覆盖。
  Future<void> _seedBuiltinData() async {
    final existingCycles = await select(lensCycles).get();
    if (existingCycles.isEmpty) {
      await batch((batch) {
        batch.insertAll(lensCycles, [
          LensCyclesCompanion.insert(
            cycleName: '日抛',
            cycleUnit: 'day',
            cycleValue: 1,
            isBuiltin: const Value(true),
            sortOrder: const Value(1),
          ),
          LensCyclesCompanion.insert(
            cycleName: '双周抛',
            cycleUnit: 'week',
            cycleValue: 2,
            isBuiltin: const Value(true),
            sortOrder: const Value(2),
          ),
          LensCyclesCompanion.insert(
            cycleName: '月抛',
            cycleUnit: 'month',
            cycleValue: 1,
            isBuiltin: const Value(true),
            sortOrder: const Value(3),
          ),
          LensCyclesCompanion.insert(
            cycleName: '季抛',
            cycleUnit: 'month',
            cycleValue: 3,
            isBuiltin: const Value(true),
            sortOrder: const Value(4),
          ),
          LensCyclesCompanion.insert(
            cycleName: '半年抛',
            cycleUnit: 'month',
            cycleValue: 6,
            isBuiltin: const Value(true),
            sortOrder: const Value(5),
          ),
          LensCyclesCompanion.insert(
            cycleName: '年抛',
            cycleUnit: 'year',
            cycleValue: 1,
            isBuiltin: const Value(true),
            sortOrder: const Value(6),
          ),
        ]);
      });
    }

    // 单例默认配置：仅当不存在时插入，不覆盖用户配置。
    await into(lensExpiryReminderSettings).insert(
      LensExpiryReminderSettingsCompanion.insert(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    await into(careSolutionChangeReminders).insert(
      CareSolutionChangeRemindersCompanion.insert(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    await into(careSolutionExpirySettings).insert(
      CareSolutionExpirySettingsCompanion.insert(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
  }
}
