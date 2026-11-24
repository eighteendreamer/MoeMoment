import 'package:drift/drift.dart';

/// 应用设置表：Key-Value 结构。
///
/// 注意：`system_notifications_enabled` 只表示应用内开关意愿，
/// 系统真实通知权限必须从操作系统读取，不能只依赖此表。
class AppSettings extends Table {
  TextColumn get key => text().withLength(min: 1)();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

/// 通知记录表：记录通知计划与发送情况，[notificationKey] 唯一用于去重。
///
/// [status] 取值：`scheduled` / `sent` / `cancelled` / `failed`。
/// 插件无法确认送达时，不能把「调度成功」记录为「已发送」。
@TableIndex(
  name: 'idx_notification_logs_target',
  columns: {#targetType, #targetId},
)
class NotificationLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get notificationKey => text().unique()();
  TextColumn get targetType => text().withLength(min: 1)();
  TextColumn get targetId => text().nullable()();
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
}
