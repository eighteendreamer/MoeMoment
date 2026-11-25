import 'package:drift/drift.dart';

import 'lens_cycles.dart';

/// 美瞳详情表。
///
/// - [status] 持久化状态仅为 `unopened` / `opened` / `discarded`；
///   `expired` 由业务层根据日期动态推导，不写入数据库。
/// - [lensSpecs] 保存镜片参数 JSON 文本，键名保持需求约定的大小写。
/// - 日期字段均为本地日历日期（TEXT `yyyy-MM-dd`）。
@DataClassName('Lens')
@TableIndex(name: 'idx_lenses_cycle', columns: {#cycleId})
@TableIndex(name: 'idx_lenses_status', columns: {#status})
class Lenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get brand => text().withLength(min: 1, max: 100)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get cycleId =>
      integer().references(LensCycles, #id, onDelete: KeyAction.restrict)();
  TextColumn get colorScheme => text().nullable()();
  TextColumn get lensSpecs => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('unopened'))();
  // 业务日期统一以 TEXT（yyyy-MM-dd）存储，与 createdAt/updatedAt 时间戳区分。
  TextColumn get openedAt => text().nullable()();
  TextColumn get packageExpiryDate => text().nullable()();
  TextColumn get discardedAt => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
