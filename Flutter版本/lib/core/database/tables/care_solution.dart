import 'package:drift/drift.dart';

/// 美瞳到期提醒设置（单例配置，默认 id = 1）。
class LensExpiryReminderSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get advanceDays => integer().withDefault(const Constant(3))();
  TextColumn get reminderTime =>
      text().withDefault(const Constant('09:00'))(); // HH:mm
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 护理液更换提醒配置（单例配置，默认 id = 1）。
///
/// [frequency] 使用稳定的枚举字符串：`daily` / `every_2_days` / `every_3_days`
/// / `weekly` / `custom`；实际计算以 [intervalDays] 为准。
class CareSolutionChangeReminders extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  IntColumn get intervalDays => integer().withDefault(const Constant(1))();
  TextColumn get reminderTime =>
      text().withDefault(const Constant('09:00'))(); // HH:mm
  // 业务日期统一以 TEXT（yyyy-MM-dd）存储。
  TextColumn get lastChangedDate => text().nullable()();
  TextColumn get nextChangedDate => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 护理液更换历史表。
class CareSolutionChangeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reminderId => integer()();
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}

/// 护理液信息表（最小可用：品牌、名称、开封日期、有效期等）。
class CareSolutionBottles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get brand => text().withLength(min: 1, max: 100)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get openedAt => text().nullable()();
  TextColumn get packageExpiryDate => text().nullable()();
  IntColumn get afterOpenValidDays => integer().nullable()();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 护理液到期提醒设置（单例配置，默认 id = 1）。
class CareSolutionExpirySettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get advanceDays => integer().withDefault(const Constant(3))();
  TextColumn get reminderTime =>
      text().withDefault(const Constant('09:00'))(); // HH:mm
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
