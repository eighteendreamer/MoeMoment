import 'package:drift/drift.dart';

/// 美瞳周期表：内置日抛、双周抛、月抛、季抛、半年抛、年抛，支持自定义周期。
///
/// [cycleUnit] 取值 `day` / `week` / `month` / `year`，实际计算以
/// [cycleUnit] + [cycleValue] 为准，不为单个周期硬编码分支。
@TableIndex(name: 'idx_lens_cycles_sort', columns: {#sortOrder})
class LensCycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cycleName => text().withLength(min: 1, max: 50)();
  TextColumn get cycleUnit => text().withLength(min: 1, max: 10)();
  IntColumn get cycleValue => integer()();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
