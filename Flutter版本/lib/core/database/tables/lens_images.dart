import 'package:drift/drift.dart';

import 'lenses.dart';

/// 美瞳图片表：一副美瞳支持多图，文件保存在 App 持久化目录。
///
/// 删除美瞳时由外键级联删除图片记录；文件清理在业务层按归属处理。
@TableIndex(name: 'idx_lens_images_lens', columns: {#lensId})
class LensImages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lensId =>
      integer().references(Lenses, #id, onDelete: KeyAction.cascade)();
  TextColumn get imagePath => text().withLength(min: 1)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
