import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show FlutterLocalNotificationsPlatform;
// ignore: implementation_imports
import 'package:flutter_local_notifications/src/platform_flutter_local_notifications.dart'
    show AndroidFlutterLocalNotificationsPlugin;
import 'package:flutter_test/flutter_test.dart';

import 'package:moe_moment/core/database/app_database.dart';
import 'package:moe_moment/core/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // 测试环境没有平台插件注册，注入方法通道实现（调用返回 null，不产生副作用）。
  FlutterLocalNotificationsPlatform.instance =
      AndroidFlutterLocalNotificationsPlugin();
  // 插件方法通道 mock：initialize/zonedSchedule 在测试环境直接成功返回。
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async => call.method == 'initialize' ? true : null,
      );
  // 平台通道实现对应 Android 分支。
  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  test('同一 notification_key 重复记录：只保留一行并更新字段', () async {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final db = AppDatabase(NativeDatabase.memory());
    final service = NotificationService(db);

    // drift 按秒精度存储，构造整秒日期保证可精确比较。
    DateTime future(int days) {
      final d = DateTime.now().add(Duration(days: days));
      return DateTime(d.year, d.month, d.day, d.hour, d.minute, d.second);
    }

    final first = future(30);
    final second = future(40);
    final ok1 = await service.schedule(
      key: 'lens_expiry_5_2027-05-25',
      when: first,
      title: '美瞳到期提醒',
      body: 'ss·aa 即将到期',
      targetType: 'lens',
      targetId: '5',
    );
    // 重排提醒：同一业务键再次安排（日期变化）。
    final ok2 = await service.schedule(
      key: 'lens_expiry_5_2027-05-25',
      when: second,
      title: '美瞳到期提醒',
      body: 'ss·aa 即将到期',
      targetType: 'lens',
      targetId: '5',
    );
    expect(ok1, isTrue, reason: '第一次调度应成功');
    expect(ok2, isTrue, reason: '同 key 重排不应再抛 UNIQUE 约束失败');

    final logs = await service.recentLogs().first;
    expect(logs.length, 1, reason: '同 key 只保留一条日志');
    expect(logs.single.status, 'scheduled');
    expect(logs.single.scheduledDate.isAtSameMomentAs(second), isTrue);
    expect(logs.single.notificationKey, 'lens_expiry_5_2027-05-25');

    await db.close();
  });
}
