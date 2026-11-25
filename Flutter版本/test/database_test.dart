import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moe_moment/core/database/app_database.dart';
import 'package:moe_moment/features/care_solution/care_solution_service.dart';
import 'package:moe_moment/features/lens/lens_repository.dart';

void main() {
  late AppDatabase db;
  late LensRepository lensRepository;
  late CareSolutionService careService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // 触发建库、外键约束与种子数据。
    await db.customSelect('SELECT 1').getSingle();
    lensRepository = LensRepository(db);
    careService = CareSolutionService(db);
  });

  tearDown(() async => db.close());

  group('初始化种子数据', () {
    test('内置周期可重复初始化且不重复插入', () async {
      final cycles = await lensRepository.getCycles();
      expect(cycles.length, 6);
      expect(cycles.where((c) => c.isBuiltin).length, 6);
      expect(
        cycles.map((c) => c.cycleName),
        containsAll(['日抛', '双周抛', '月抛', '季抛', '半年抛', '年抛']),
      );

      // 再次打开同一数据库（模拟重启），不重复插入、不覆盖用户配置。
      final lensSettings = await (db.select(db.lensExpiryReminderSettings))
          .get();
      expect(lensSettings, hasLength(1));
      expect(lensSettings.first.advanceDays, 3);
      expect(lensSettings.first.isActive, isTrue);
    });

    test('默认提醒配置存在', () async {
      final change = await careService.watchChangeReminder().first;
      expect(change.intervalDays, 1);
      expect(change.frequency, 'daily');
      final expiry = await careService.watchExpirySettings().first;
      expect(expiry.advanceDays, 3);
    });
  });

  group('美瞳保存与外键', () {
    test('保存美瞳及图片（同一事务）并读取详情', () async {
      final cycles = await lensRepository.getCycles();
      final lensId = await lensRepository.saveLens(
        brand: 'Olens',
        name: 'Scandi Hazel',
        cycleId: cycles.first.id,
        colorScheme: 'Hazel',
        lensSpecsJson: '{"Lens_diameter": 14.2}',
        status: 'unopened',
        note: '日常款',
        newImagePaths: ['/tmp/a.jpg', '/tmp/b.jpg'],
      );

      final detail = await lensRepository.watchLens(lensId).first;
      expect(detail, isNotNull);
      expect(detail!.lens.brand, 'Olens');
      expect(detail.images, hasLength(2));
      expect(detail.images[0].imagePath, '/tmp/a.jpg');
      expect(detail.images[0].sortOrder, 0);
      expect(detail.images[1].sortOrder, 1);
    });

    test('编辑美瞳更新字段并归一化图片排序', () async {
      final cycles = await lensRepository.getCycles();
      final lensId = await lensRepository.saveLens(
        brand: 'Olens',
        name: 'Scandi Hazel',
        cycleId: cycles.first.id,
        status: 'unopened',
        newImagePaths: const ['/tmp/a.jpg', '/tmp/b.jpg', '/tmp/c.jpg'],
      );

      // 删除中间一张，剩余两张应重新排序为 0、1。
      final images =
          await (db.select(
              db.lensImages,
            )..where((t) => t.lensId.equals(lensId))).get()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      await lensRepository.deleteImage(images[1].id);

      final after =
          await (db.select(
              db.lensImages,
            )..where((t) => t.lensId.equals(lensId))).get()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(after, hasLength(2));
      expect(after[0].sortOrder, 0);
      expect(after[1].sortOrder, 1);
    });

    test('内置周期不能删除', () async {
      final cycles = await lensRepository.getCycles();
      expect(
        () => lensRepository.deleteCycle(cycles.first.id),
        throwsStateError,
      );
    });

    test('被美瞳引用的周期不能删除（外键 RESTRICT 兜底）', () async {
      final cycles = await lensRepository.getCycles();
      final custom = await lensRepository.addCustomCycle(
        name: '10 天',
        unit: 'day',
        value: 10,
      );
      await lensRepository.saveLens(
        brand: 'Olens',
        name: 'Test',
        cycleId: custom.id,
        status: 'unopened',
      );
      expect(() => lensRepository.deleteCycle(custom.id), throwsStateError);
      expect(cycles.length, 6);
    });

    test('未被引用的自定义周期可以删除', () async {
      final custom = await lensRepository.addCustomCycle(
        name: '3 周',
        unit: 'week',
        value: 3,
      );
      await lensRepository.deleteCycle(custom.id);
      final cycles = await lensRepository.getCycles();
      expect(cycles.where((c) => c.id == custom.id), isEmpty);
    });

    test('删除美瞳级联删除图片记录', () async {
      final cycles = await lensRepository.getCycles();
      final lensId = await lensRepository.saveLens(
        brand: 'Olens',
        name: 'Test',
        cycleId: cycles.first.id,
        status: 'unopened',
        newImagePaths: const ['/tmp/a.jpg'],
      );
      final paths = await lensRepository.deleteLens(lensId);
      expect(paths, ['/tmp/a.jpg']);
      final images = await (db.select(
        db.lensImages,
      )..where((t) => t.lensId.equals(lensId))).get();
      expect(images, isEmpty);
    });

    test('开封与丢弃更新状态和日期', () async {
      final cycles = await lensRepository.getCycles();
      final lensId = await lensRepository.saveLens(
        brand: 'Olens',
        name: 'Test',
        cycleId: cycles.first.id,
        status: 'unopened',
      );
      await lensRepository.openLens(lensId, DateTime(2026, 11, 1));
      var lens = await (db.select(
        db.lenses,
      )..where((t) => t.id.equals(lensId))).getSingle();
      expect(lens.status, 'opened');
      expect(lens.openedAt, '2026-11-01');

      await lensRepository.discardLens(lensId, DateTime(2026, 11, 10));
      lens = await (db.select(
        db.lenses,
      )..where((t) => t.id.equals(lensId))).getSingle();
      expect(lens.status, 'discarded');
      expect(lens.discardedAt, '2026-11-10');
    });
  });

  group('护理液更换事务', () {
    test('markChanged 在同一事务写历史并更新日期', () async {
      await careService.updateChangeReminder(
        isActive: true,
        frequency: ChangeFrequency.every2Days,
        intervalDays: 2,
        reminderTime: '09:00',
      );
      final (logId, next) = await careService.markChanged(
        note: '首次更换',
        changedDate: DateTime(2026, 11, 24),
      );
      expect(logId, greaterThan(0));
      expect(next, DateTime(2026, 11, 26));

      final config = await careService.watchChangeReminder().first;
      expect(config.lastChangedDate, '2026-11-24');
      expect(config.nextChangedDate, '2026-11-26');

      final logs = await careService.watchChangeLogs().first;
      expect(logs, hasLength(1));
      expect(logs.first.note, '首次更换');
    });

    test('recalculateNextChangeDate 按新间隔重算', () async {
      await careService.markChanged(changedDate: DateTime(2026, 11, 1));
      await careService.updateChangeReminder(
        isActive: true,
        frequency: ChangeFrequency.weekly,
        intervalDays: 7,
        reminderTime: '09:00',
      );
      final next = await careService.recalculateNextChangeDate();
      expect(next, DateTime(2026, 11, 8));
    });

    test('保存护理液并切换「当前使用」标记', () async {
      final id1 = await careService.saveBottle(
        brand: '海昌',
        name: '透明质酸',
        openedAt: DateTime(2026, 11, 1),
        afterOpenValidDays: 30,
        isCurrent: true,
      );
      final id2 = await careService.saveBottle(
        brand: '乐敦',
        name: 'C3',
        packageExpiryDate: DateTime(2027, 1, 1),
        isCurrent: true,
      );
      final current = await careService.watchCurrentBottle().first;
      expect(current!.id, id2);

      final bottles = await careService.watchBottles().first;
      expect(bottles.where((b) => b.isCurrent), hasLength(1));
      expect(bottles.map((b) => b.id), containsAll([id1, id2]));
    });

    test('护理液到期日取包装有效期与开封后有效期的较早者', () async {
      await careService.saveBottle(
        brand: '海昌',
        name: '透明质酸',
        openedAt: DateTime(2026, 11, 1),
        afterOpenValidDays: 30,
        packageExpiryDate: DateTime(2026, 11, 20),
        isCurrent: true,
      );
      final bottle = await careService.watchCurrentBottle().first;
      expect(careService.bottleExpiryDate(bottle!), DateTime(2026, 11, 20));
    });
  });

  group('App 设置与通知日志去重', () {
    test('设置键值写入与覆盖', () async {
      await careService.setSetting('github_mirror_mode', 'auto');
      expect(await careService.getSetting('github_mirror_mode'), 'auto');
      await careService.setSetting('github_mirror_mode', 'mirror');
      expect(await careService.getSetting('github_mirror_mode'), 'mirror');
    });

    test('notificationKey 唯一约束防重复', () async {
      await db
          .into(db.notificationLogs)
          .insert(
            NotificationLogsCompanion.insert(
              notificationKey: 'lens_expiry_1_2026-12-01',
              targetType: 'lens',
              scheduledDate: DateTime(2026, 12, 1, 9),
            ),
          );
      // 同键插入触发唯一约束异常。
      expect(
        () => db
            .into(db.notificationLogs)
            .insert(
              NotificationLogsCompanion.insert(
                notificationKey: 'lens_expiry_1_2026-12-01',
                targetType: 'lens',
                scheduledDate: DateTime(2026, 12, 1, 9),
              ),
            ),
        throwsA(anything),
      );
    });
  });
}
