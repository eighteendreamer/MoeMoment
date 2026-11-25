import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/database/app_database.dart';
import '../../core/database/converters.dart';

/// 本地通知服务：权限、调度、取消与去重的唯一入口。
///
/// - 首次启用提醒时才请求权限，不在启动时无条件弹授权框。
/// - 计划、取消与日志去重都使用稳定的 `notificationKey`。
/// - 通知是外部副作用：数据库提交成功后才执行调度，失败记录日志。
class NotificationService {
  NotificationService(this._db);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AppDatabase _db;
  bool _initialized = false;

  static const _channelId = 'moe_moment_reminders';
  static const _channelName = '美瞳与护理液提醒';
  static const _channelDescription = '美瞳到期、护理液更换与护理液到期提醒';

  /// 应用启动时调用：初始化插件与时区，并处理点击回调。
  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('获取本地时区失败，使用系统默认: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        windows: WindowsInitializationSettings(
          appName: '美瞳管理',
          appUserModelId: 'Com.MomeMoment.MoeMoment',
          // 标识 Windows 通知激活回调的固定 GUID（生成一次后保持不变）。
          guid: 'A8C1E7D2-4F5B-4C8A-9D3E-1B2C3D4E5F60',
        ),
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final key = response.payload;
    if (key == null || key.isEmpty) return;
    await (_db.update(
      _db.notificationLogs,
    )..where((t) => t.notificationKey.equals(key))).write(
      NotificationLogsCompanion(
        status: const Value('sent'),
        sentAt: Value(DateTime.now()),
      ),
    );
  }

  /// 系统真实通知权限状态（区分数据库开关与系统授权）。
  Future<bool> isSystemPermissionGranted() async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final perms = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return perms?.isEnabled ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      // Windows 桌面通知没有移动端式的运行时权限弹窗，注册后即视为可用。
      return _initialized;
    }
    return false;
  }

  /// 请求通知权限（仅在用户首次启用提醒时调用）。
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _initialized;
    }
    return false;
  }

  /// 稳定的通知 ID：由业务键哈希生成，避免重复安排。
  static int notificationId(String key) => key.hashCode & 0x7fffffff;

  /// 取消一条待触发通知并标记日志为已取消。
  Future<void> cancelByKey(String key) async {
    await _plugin.cancel(id: notificationId(key));
    await (_db.update(_db.notificationLogs)..where(
          (t) => t.notificationKey.equals(key) & t.status.equals('scheduled'),
        ))
        .write(NotificationLogsCompanion(status: const Value('cancelled')));
  }

  /// 安排一条通知：到点时间必须是本地未来时间。
  ///
  /// 插件无法确认送达；调度成功只记录 `scheduled`，实际触发后才记 `sent`。
  Future<bool> schedule({
    required String key,
    required DateTime when,
    required String title,
    required String body,
    required String targetType,
    required String? targetId,
  }) async {
    if (!_initialized) await initialize();
    final fireAt = TZHelper.fromLocal(when);
    if (!fireAt.isAfter(TZHelper.now())) {
      return false; // 过去时间不安排。
    }

    // 去重：同一业务键已存在则先取消旧的。
    await _plugin.cancel(id: notificationId(key));

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: notificationId(key),
        title: title,
        body: body,
        scheduledDate: fireAt,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: key,
      );
    } catch (e) {
      await _recordLog(key, targetType, targetId, when, status: 'failed');
      debugPrint('调度通知失败: $key, $e');
      return false;
    }

    await _recordLog(key, targetType, targetId, when, status: 'scheduled');
    return true;
  }

  /// 记录通知日志。同一 notification_key 只保留一条，重排/重试时原地更新，
  /// 不产生重复行（notification_key 有 UNIQUE 约束）。
  Future<void> _recordLog(
    String key,
    String targetType,
    String? targetId,
    DateTime scheduledDate, {
    required String status,
  }) {
    return _db
        .into(_db.notificationLogs)
        .insert(
          NotificationLogsCompanion.insert(
            notificationKey: key,
            targetType: targetType,
            targetId: Value(targetId),
            scheduledDate: scheduledDate,
            status: Value(status),
          ),
          onConflict: DoUpdate(
            (old) => NotificationLogsCompanion(
              targetType: Value(targetType),
              targetId: Value(targetId),
              scheduledDate: Value(scheduledDate),
              status: Value(status),
            ),
            target: [_db.notificationLogs.notificationKey],
          ),
        );
  }

  Stream<List<NotificationLog>> recentLogs() {
    return (_db.select(_db.notificationLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledDate)])
          ..limit(50))
        .watch();
  }

  /// 取消全部待触发通知（关闭通知总开关时使用）。
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await (_db.update(_db.notificationLogs)
          ..where((t) => t.status.equals('scheduled')))
        .write(NotificationLogsCompanion(status: const Value('cancelled')));
  }
}

/// 本地时区时间工具。
class TZHelper {
  /// 将本地 DateTime 转为本地时区计划时间。
  static tz.TZDateTime fromLocal(DateTime local) =>
      tz.TZDateTime.from(local, tz.local);

  static tz.TZDateTime now() => tz.TZDateTime.now(tz.local);

  /// 指定日期 + HH:mm 组合成本地计划时间。
  static tz.TZDateTime at(DateTime date, TimeOfDayText time) {
    final d = DateIsoConverter.toLocalDate(date);
    return fromLocal(DateTime(d.year, d.month, d.day, time.hour, time.minute));
  }
}
