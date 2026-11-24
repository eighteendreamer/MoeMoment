import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_services.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  // 触发数据库打开与初始化（内置周期、默认配置、外键约束）。
  await db.customSelect('SELECT 1').getSingle();
  final services = AppServices(db: db);
  await services.notifications.initialize();
  // 启动时校验并恢复未来提醒计划。
  await services.reminders.resyncAll();

  runApp(Provider.value(value: services, child: const MoeMomentApp()));
}
