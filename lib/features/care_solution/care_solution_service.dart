import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/converters.dart';
import '../../core/date/date_service.dart';

/// 护理液更换频率选项（稳定枚举字符串；计算以 intervalDays 为准）。
enum ChangeFrequency {
  daily('daily', '每天', 1),
  every2Days('every_2_days', '每 2 天', 2),
  every3Days('every_3_days', '每 3 天', 3),
  weekly('weekly', '每周', 7),
  custom('custom', '自定义', 1);

  const ChangeFrequency(this.dbValue, this.display, this.defaultInterval);
  final String dbValue;
  final String display;
  final int defaultInterval;

  static ChangeFrequency fromDb(String? value, {int? intervalDays}) {
    final match = ChangeFrequency.values
        .where((f) => f.dbValue == value)
        .firstOrNull;
    if (match != null) return match;
    if (intervalDays != null) {
      final byInterval = ChangeFrequency.values
          .where(
            (f) =>
                f != ChangeFrequency.custom &&
                f.defaultInterval == intervalDays,
          )
          .firstOrNull;
      if (byInterval != null) return byInterval;
    }
    return ChangeFrequency.daily;
  }
}

/// 护理液业务：更换记录事务、到期日计算。
class CareSolutionService {
  CareSolutionService(this._db);

  final AppDatabase _db;
  final DateService _dates = const DateService();

  /// 更换提醒配置（响应式）。
  Stream<CareSolutionChangeReminder> watchChangeReminder() {
    return (_db.select(
      _db.careSolutionChangeReminders,
    )..where((t) => t.id.equals(1))).watchSingle();
  }

  /// 护理液到期提醒设置（响应式）。
  Stream<CareSolutionExpirySetting> watchExpirySettings() {
    return (_db.select(
      _db.careSolutionExpirySettings,
    )..where((t) => t.id.equals(1))).watchSingle();
  }

  /// 美瞳到期提醒设置（响应式）。
  Stream<LensExpiryReminderSetting> watchLensExpirySettings() {
    return (_db.select(
      _db.lensExpiryReminderSettings,
    )..where((t) => t.id.equals(1))).watchSingle();
  }

  /// 当前使用的护理液（响应式）。
  Stream<CareSolutionBottle?> watchCurrentBottle() {
    return (_db.select(_db.careSolutionBottles)
          ..where((t) => t.isCurrent.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watchSingleOrNull();
  }

  /// 全部护理液（响应式）。
  Stream<List<CareSolutionBottle>> watchBottles() {
    return (_db.select(
      _db.careSolutionBottles,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// 更换历史（响应式）。
  Stream<List<CareSolutionChangeLog>> watchChangeLogs() {
    return (_db.select(
      _db.careSolutionChangeLogs,
    )..orderBy([(t) => OrderingTerm.desc(t.changedAt)])).watch();
  }

  /// 「已更换护理液」：同一事务中写入历史、更新上次日期并计算下次日期。
  ///
  /// 返回（记录 id, 下次更换日期）。事务提交成功后由上层重排通知。
  Future<(int, DateTime)> markChanged({
    String? note,
    DateTime? changedDate,
  }) async {
    return _db.transaction(() async {
      final config = await (_db.select(
        _db.careSolutionChangeReminders,
      )..where((t) => t.id.equals(1))).getSingle();
      final date = DateIsoConverter.toLocalDate(changedDate ?? DateTime.now());
      final dateText = DateIsoConverter.encode(date);
      final next = date.add(Duration(days: config.intervalDays.clamp(1, 3650)));

      final logId = await _db
          .into(_db.careSolutionChangeLogs)
          .insert(
            CareSolutionChangeLogsCompanion.insert(
              reminderId: config.id,
              changedAt: Value(date),
              note: Value(note),
            ),
          );
      await (_db.update(
        _db.careSolutionChangeReminders,
      )..where((t) => t.id.equals(config.id))).write(
        CareSolutionChangeRemindersCompanion(
          lastChangedDate: Value(dateText),
          nextChangedDate: Value(DateIsoConverter.encode(next)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (logId, next);
    });
  }

  /// 根据间隔重算下次更换日期（不写历史），用于配置变化后刷新。
  Future<DateTime?> recalculateNextChangeDate() async {
    final config = await (_db.select(
      _db.careSolutionChangeReminders,
    )..where((t) => t.id.equals(1))).getSingle();
    final base = DateIsoConverter.tryParse(config.lastChangedDate);
    if (base == null) return null;
    final next = base.add(Duration(days: config.intervalDays.clamp(1, 3650)));
    await (_db.update(
      _db.careSolutionChangeReminders,
    )..where((t) => t.id.equals(config.id))).write(
      CareSolutionChangeRemindersCompanion(
        nextChangedDate: Value(DateIsoConverter.encode(next)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return next;
  }

  /// 更新更换提醒配置。
  Future<void> updateChangeReminder({
    required bool isActive,
    required ChangeFrequency frequency,
    required int intervalDays,
    required String reminderTime,
  }) {
    return (_db.update(
      _db.careSolutionChangeReminders,
    )..where((t) => t.id.equals(1))).write(
      CareSolutionChangeRemindersCompanion(
        isActive: Value(isActive),
        frequency: Value(frequency.dbValue),
        intervalDays: Value(intervalDays.clamp(1, 3650)),
        reminderTime: Value(reminderTime),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新护理液到期提醒设置。
  Future<void> updateExpirySettings({
    required bool isActive,
    required int advanceDays,
    required String reminderTime,
  }) {
    return (_db.update(
      _db.careSolutionExpirySettings,
    )..where((t) => t.id.equals(1))).write(
      CareSolutionExpirySettingsCompanion(
        isActive: Value(isActive),
        advanceDays: Value(advanceDays.clamp(0, 365)),
        reminderTime: Value(reminderTime),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新美瞳到期提醒设置。
  Future<void> updateLensExpirySettings({
    required bool isActive,
    required int advanceDays,
    required String reminderTime,
  }) {
    return (_db.update(
      _db.lensExpiryReminderSettings,
    )..where((t) => t.id.equals(1))).write(
      LensExpiryReminderSettingsCompanion(
        isActive: Value(isActive),
        advanceDays: Value(advanceDays.clamp(0, 365)),
        reminderTime: Value(reminderTime),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 保存护理液信息；设为当前使用时取消其他瓶的当前标记（同一事务）。
  Future<int> saveBottle({
    required String brand,
    required String name,
    DateTime? openedAt,
    DateTime? packageExpiryDate,
    int? afterOpenValidDays,
    required bool isCurrent,
    String? note,
    int? existingId,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now();
      if (isCurrent) {
        await (_db.update(_db.careSolutionBottles)
              ..where((t) => t.isCurrent.equals(true)))
            .write(CareSolutionBottlesCompanion(isCurrent: const Value(false)));
      }
      final changes = CareSolutionBottlesCompanion(
        brand: Value(brand),
        name: Value(name),
        openedAt: Value(
          openedAt == null ? null : DateIsoConverter.encode(openedAt),
        ),
        packageExpiryDate: Value(
          packageExpiryDate == null
              ? null
              : DateIsoConverter.encode(packageExpiryDate),
        ),
        afterOpenValidDays: Value(afterOpenValidDays),
        isCurrent: Value(isCurrent),
        note: Value(note),
        updatedAt: Value(now),
      );
      if (existingId == null) {
        return _db
            .into(_db.careSolutionBottles)
            .insert(changes.copyWith(createdAt: Value(now)));
      }
      await (_db.update(
        _db.careSolutionBottles,
      )..where((t) => t.id.equals(existingId))).write(changes);
      return existingId;
    });
  }

  /// 删除护理液（数据库层面；不删除其他瓶数据）。
  Future<void> deleteBottle(int bottleId) async {
    await (_db.delete(
      _db.careSolutionBottles,
    )..where((t) => t.id.equals(bottleId))).go();
  }

  /// 护理液到期日：包装有效期与「开封日期 + 开封后有效天数」取较早者；
  /// 缺少依据返回 null，由界面提示补充。
  DateTime? bottleExpiryDate(CareSolutionBottle bottle) {
    return _dates.careSolutionExpiryDate(
      packageExpiryDate: DateIsoConverter.tryParse(bottle.packageExpiryDate),
      openedAt: DateIsoConverter.tryParse(bottle.openedAt),
      afterOpenValidDays: bottle.afterOpenValidDays,
    );
  }

  /// App 设置读写。
  Future<String?> getSetting(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) {
    return _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: Value(value)),
        );
  }

  Stream<Map<String, String>> watchSettings() {
    return (_db.select(_db.appSettings))
        .watch()
        .map((rows) => {for (final row in rows) row.key: row.value ?? ''});
  }
}
