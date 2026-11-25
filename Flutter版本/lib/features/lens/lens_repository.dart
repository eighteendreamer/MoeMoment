import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/converters.dart';

/// 两个流的最新值组合工具（drift 流的轻量 combine）。
Stream<C> combine2<A, B, C>(
  Stream<A> streamA,
  Stream<B> streamB,
  C Function(A a, B b) combiner,
) {
  late StreamController<C> controller;
  A? latestA;
  B? latestB;
  bool hasA = false;
  bool hasB = false;

  void emit() {
    if (hasA && hasB) {
      controller.add(combiner(latestA as A, latestB as B));
    }
  }

  Future<void> close() async {
    await controller.close();
  }

  controller = StreamController<C>(
    onListen: () {
      final subA = streamA.listen((a) {
        latestA = a;
        hasA = true;
        emit();
      }, onError: controller.addError);
      final subB = streamB.listen((b) {
        latestB = b;
        hasB = true;
        emit();
      }, onError: controller.addError);
      controller.onCancel = () async {
        await subA.cancel();
        await subB.cancel();
        await close();
      };
    },
    onPause: () {},
    onResume: () {},
  );
  return controller.stream;
}

/// 列表项：美瞳 + 周期 + 封面图。
class LensWithMeta {
  const LensWithMeta({
    required this.lens,
    required this.cycle,
    this.coverImagePath,
  });

  final Lens lens;
  final LensCycle cycle;
  final String? coverImagePath;
}

/// 详情项：美瞳 + 周期 + 全部图片。
class LensDetail {
  const LensDetail({
    required this.lens,
    required this.cycle,
    required this.images,
  });

  final Lens lens;
  final LensCycle cycle;
  final List<LensImage> images;
}

/// 美瞳数据仓库：封装数据库访问与跨表事务。
class LensRepository {
  LensRepository(this._db);

  final AppDatabase _db;

  /// 响应式美瞳列表（含周期与封面图路径）。
  Stream<List<LensWithMeta>> watchAllLenses() {
    final lensQuery = _db.select(_db.lenses).join([
      innerJoin(
        _db.lensCycles,
        _db.lensCycles.id.equalsExp(_db.lenses.cycleId),
      ),
    ])..orderBy([OrderingTerm.desc(_db.lenses.createdAt)]);
    final imagesQuery = _db.select(_db.lensImages);

    return combine2(lensQuery.watch(), imagesQuery.watch(), (rows, images) {
      String? coverFor(int lensId) {
        final owned = images.where((img) => img.lensId == lensId).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return owned.isEmpty ? null : owned.first.imagePath;
      }

      return rows
          .map(
            (row) => LensWithMeta(
              lens: row.readTable(_db.lenses),
              cycle: row.readTable(_db.lensCycles),
              coverImagePath: coverFor(row.readTable(_db.lenses).id),
            ),
          )
          .toList();
    });
  }

  /// 单副美瞳详情（含全部图片，响应式）。
  Stream<LensDetail?> watchLens(int lensId) {
    final lensQuery = _db.select(_db.lenses).join([
      innerJoin(
        _db.lensCycles,
        _db.lensCycles.id.equalsExp(_db.lenses.cycleId),
      ),
    ])..where(_db.lenses.id.equals(lensId));
    final imagesQuery = _db.select(_db.lensImages)
      ..where((t) => t.lensId.equals(lensId));

    return combine2(lensQuery.watchSingleOrNull(), imagesQuery.watch(), (
      row,
      images,
    ) {
      if (row == null) return null;
      final sorted = images.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return LensDetail(
        lens: row.readTable(_db.lenses),
        cycle: row.readTable(_db.lensCycles),
        images: sorted,
      );
    });
  }

  /// 保存美瞳及图片记录：数据库写入放在同一事务。
  ///
  /// 图片文件先落盘再进入本方法；事务失败抛出异常，由上层清理已复制文件。
  Future<int> saveLens({
    required String brand,
    required String name,
    required int cycleId,
    String? colorScheme,
    String? lensSpecsJson,
    required String status,
    DateTime? openedAt,
    DateTime? packageExpiryDate,
    DateTime? discardedAt,
    String? note,
    int? existingId,
    List<String> newImagePaths = const [],
    List<int> deleteImageIds = const [],
  }) {
    return _db.transaction(() async {
      final now = DateTime.now();
      final changes = LensesCompanion(
        brand: Value(brand),
        name: Value(name),
        cycleId: Value(cycleId),
        colorScheme: Value(colorScheme),
        lensSpecs: Value(lensSpecsJson),
        status: Value(status),
        openedAt: Value(
          openedAt == null ? null : DateIsoConverter.encode(openedAt),
        ),
        packageExpiryDate: Value(
          packageExpiryDate == null
              ? null
              : DateIsoConverter.encode(packageExpiryDate),
        ),
        discardedAt: Value(
          discardedAt == null ? null : DateIsoConverter.encode(discardedAt),
        ),
        note: Value(note),
        updatedAt: Value(now),
      );

      int lensId;
      if (existingId == null) {
        lensId = await _db
            .into(_db.lenses)
            .insert(changes.copyWith(createdAt: Value(now)));
      } else {
        lensId = existingId;
        await (_db.update(
          _db.lenses,
        )..where((t) => t.id.equals(existingId))).write(changes);
      }

      for (final imageId in deleteImageIds) {
        await (_db.delete(
          _db.lensImages,
        )..where((t) => t.id.equals(imageId))).go();
      }

      for (final path in newImagePaths) {
        await _db
            .into(_db.lensImages)
            .insert(
              LensImagesCompanion.insert(lensId: lensId, imagePath: path),
            );
      }

      // 归一化排序。
      final images =
          await (_db.select(
              _db.lensImages,
            )..where((t) => t.lensId.equals(lensId))).get()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (var i = 0; i < images.length; i++) {
        if (images[i].sortOrder != i) {
          await (_db.update(_db.lensImages)
                ..where((t) => t.id.equals(images[i].id)))
              .write(LensImagesCompanion(sortOrder: Value(i)));
        }
      }
      return lensId;
    });
  }

  /// 标记开封。
  Future<void> openLens(int lensId, DateTime openedDate) {
    return _db.transaction(() async {
      await (_db.update(_db.lenses)..where((t) => t.id.equals(lensId))).write(
        LensesCompanion(
          status: const Value('opened'),
          openedAt: Value(DateIsoConverter.encode(openedDate)),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// 标记丢弃。
  Future<void> discardLens(int lensId, DateTime discardedDate) {
    return _db.transaction(() async {
      await (_db.update(_db.lenses)..where((t) => t.id.equals(lensId))).write(
        LensesCompanion(
          status: const Value('discarded'),
          discardedAt: Value(DateIsoConverter.encode(discardedDate)),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// 删除美瞳：数据库级联删除图片记录；返回图片路径供事务成功后清理文件。
  Future<List<String>> deleteLens(int lensId) async {
    final images = await (_db.select(
      _db.lensImages,
    )..where((t) => t.lensId.equals(lensId))).get();
    await _db.transaction(() async {
      await (_db.delete(_db.lenses)..where((t) => t.id.equals(lensId))).go();
    });
    return images.map((e) => e.imagePath).toList();
  }

  /// 删除指定单张图片记录并归一化剩余排序，返回被删文件路径。
  Future<String?> deleteImage(int imageId) {
    return _db.transaction(() async {
      final image = await (_db.select(
        _db.lensImages,
      )..where((t) => t.id.equals(imageId))).getSingleOrNull();
      if (image == null) return null;
      await (_db.delete(
        _db.lensImages,
      )..where((t) => t.id.equals(imageId))).go();

      final remaining =
          await (_db.select(
              _db.lensImages,
            )..where((t) => t.lensId.equals(image.lensId))).get()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (var i = 0; i < remaining.length; i++) {
        if (remaining[i].sortOrder != i) {
          await (_db.update(_db.lensImages)
                ..where((t) => t.id.equals(remaining[i].id)))
              .write(LensImagesCompanion(sortOrder: Value(i)));
        }
      }
      return image.imagePath;
    });
  }

  /// 周期列表（响应式）。
  Stream<List<LensCycle>> watchCycles() {
    return (_db.select(_db.lensCycles)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .watch();
  }

  Future<List<LensCycle>> getCycles() => watchCycles().first;

  /// 新增自定义周期。
  Future<LensCycle> addCustomCycle({
    required String name,
    required String unit,
    required int value,
  }) async {
    final maxSort =
        await (_db.select(_db.lensCycles)
              ..orderBy([(t) => OrderingTerm.desc(t.sortOrder)])
              ..limit(1))
            .getSingleOrNull();
    final id = await _db
        .into(_db.lensCycles)
        .insert(
          LensCyclesCompanion.insert(
            cycleName: name,
            cycleUnit: unit,
            cycleValue: value,
            sortOrder: Value((maxSort?.sortOrder ?? 0) + 1),
          ),
        );
    return (_db.select(
      _db.lensCycles,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  /// 删除自定义周期；内置周期或被引用周期直接抛错（外键 RESTRICT 兜底）。
  Future<void> deleteCycle(int cycleId) async {
    final cycle = await (_db.select(
      _db.lensCycles,
    )..where((t) => t.id.equals(cycleId))).getSingleOrNull();
    if (cycle == null) return;
    if (cycle.isBuiltin) {
      throw StateError('内置周期不能删除');
    }
    final referenced = await (_db.select(
      _db.lenses,
    )..where((t) => t.cycleId.equals(cycleId))).get();
    if (referenced.isNotEmpty) {
      throw StateError('该周期已被 ${referenced.length} 副美瞳引用，不能删除');
    }
    await (_db.delete(_db.lensCycles)..where((t) => t.id.equals(cycleId))).go();
  }
}
