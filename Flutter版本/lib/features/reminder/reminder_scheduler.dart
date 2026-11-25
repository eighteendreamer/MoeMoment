import 'package:flutter/foundation.dart';

import '../../core/database/converters.dart';
import '../../core/date/date_service.dart';
import '../../core/notifications/notification_service.dart';
import '../care_solution/care_solution_service.dart';
import '../lens/lens_repository.dart';
import '../lens/lens_service.dart';

/// 提醒调度编排：三类提醒独立计算，统一全量重排。
///
/// - 通知是外部副作用，只在数据库状态读取完成后执行调度。
/// - 每次全量重排保证：新增/编辑/开封/丢弃/删除、日期与间隔变化、
///   开关变化后计划与数据库状态一致；`notificationKey` 唯一防重复。
class ReminderScheduler {
  ReminderScheduler(
    this._notifications,
    this._lensRepository,
    this._lensService,
    this._careService,
  );

  final NotificationService _notifications;
  final LensRepository _lensRepository;
  final LensService _lensService;
  final CareSolutionService _careService;

  /// 读取当前数据库状态，重排全部未来通知。
  Future<void> resyncAll() async {
    try {
      await _notifications.initialize();

      final masterEnabled = await _careService.getSetting(
        'system_notifications_enabled',
      );
      if (masterEnabled != 'true') {
        await _notifications.cancelAll();
        return;
      }

      // 系统权限被撤销时不安排，避免伪装调度成功。
      final granted = await _notifications.isSystemPermissionGranted();
      if (!granted) {
        await _notifications.cancelAll();
        return;
      }

      await _notifications.cancelAll();
      await _scheduleLensExpiryReminders();
      await _scheduleCareChangeReminder();
      await _scheduleCareExpiryReminder();
    } catch (e) {
      debugPrint('重排提醒失败: $e');
    }
  }

  Future<void> _scheduleLensExpiryReminders() async {
    final settings = await _careService.watchLensExpirySettings().first;
    if (!settings.isActive) return;

    final lenses = await _lensRepository.watchAllLenses().first;
    final reminderTime = TimeOfDayText.parse(settings.reminderTime);
    for (final item in lenses) {
      final view = _lensService.buildView(item.lens, item.cycle);
      final expiry = view.expiryDate;
      if (expiry == null) continue;
      final reminderDate = DateIsoConverter.toLocalDate(
        DateService().reminderDate(
          expiryDate: expiry,
          advanceDays: settings.advanceDays,
        ),
      );
      final key =
          'lens_expiry_${item.lens.id}_${DateIsoConverter.encode(expiry)}';
      final fireAt = TZHelper.at(reminderDate, reminderTime);
      if (fireAt.isAfter(TZHelper.now())) {
        await _notifications.schedule(
          key: key,
          when: DateTime(
            fireAt.year,
            fireAt.month,
            fireAt.day,
            fireAt.hour,
            fireAt.minute,
          ),
          title: '美瞳即将到期',
          body:
              '${item.lens.brand} ${item.lens.name} 将于 ${DateIsoConverter.encode(expiry)} 到期，请及时更换。',
          targetType: 'lens',
          targetId: '${item.lens.id}',
        );
      }
    }
  }

  Future<void> _scheduleCareChangeReminder() async {
    final config = await _careService.watchChangeReminder().first;
    if (!config.isActive) return;
    final next = DateIsoConverter.tryParse(config.nextChangedDate);
    if (next == null) return;
    final reminderTime = TimeOfDayText.parse(config.reminderTime);
    final fireAt = TZHelper.at(
      DateIsoConverter.toLocalDate(next),
      reminderTime,
    );
    if (!fireAt.isAfter(TZHelper.now())) return;
    await _notifications.schedule(
      key: 'care_change_${config.id}_${DateIsoConverter.encode(next)}',
      when: DateTime(
        fireAt.year,
        fireAt.month,
        fireAt.day,
        fireAt.hour,
        fireAt.minute,
      ),
      title: '请更换护理液',
      body: '今天是计划更换护理液的日期（${DateIsoConverter.encode(next)}）。',
      targetType: 'care_change',
      targetId: '${config.id}',
    );
  }

  Future<void> _scheduleCareExpiryReminder() async {
    final settings = await _careService.watchExpirySettings().first;
    if (!settings.isActive) return;
    final bottle = await _careService.watchCurrentBottle().first;
    if (bottle == null) return;
    final expiry = _careService.bottleExpiryDate(bottle);
    if (expiry == null) return;
    final reminderDate = DateIsoConverter.toLocalDate(
      DateService().reminderDate(
        expiryDate: expiry,
        advanceDays: settings.advanceDays,
      ),
    );
    final reminderTime = TimeOfDayText.parse(settings.reminderTime);
    final fireAt = TZHelper.at(reminderDate, reminderTime);
    if (!fireAt.isAfter(TZHelper.now())) return;
    await _notifications.schedule(
      key: 'care_expiry_${bottle.id}_${DateIsoConverter.encode(expiry)}',
      when: DateTime(
        fireAt.year,
        fireAt.month,
        fireAt.day,
        fireAt.hour,
        fireAt.minute,
      ),
      title: '护理液即将到期',
      body: '当前护理液（${bottle.brand} ${bottle.name}）即将到期，请及时检查。',
      targetType: 'care_expiry',
      targetId: '${bottle.id}',
    );
  }
}
