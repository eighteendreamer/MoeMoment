import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import 'package:moe_moment/app/app_services.dart';
import 'package:moe_moment/app/theme/app_theme.dart';
import 'package:moe_moment/core/database/app_database.dart';
import 'package:moe_moment/features/settings/profile_page.dart';

void main() {
  testWidgets('我的页：标题贴近顶部，不随内容垂直居中', (tester) async {
    // 模拟 package_info 通道，避免测试环境插件缺失。
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => {
              'appName': 'moe_moment',
              'packageName': 'com.example.moe_moment',
              'version': '1.0.0',
              'buildNumber': '1',
            });

    final db = AppDatabase(NativeDatabase.memory());
    final services = AppServices(db: db);
    // 足够高的视口，复现“内容不足一屏”的场景。
    await tester.binding.setSurfaceSize(const Size(800, 1400));

    await tester.pumpWidget(
      Provider.value(
        value: services,
        child: FTheme(
          data: AppTheme.build(),
          child: MaterialApp(home: ProfilePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 标题应与首页一致贴在顶部，而不是被垂直居中到页面中部。
    final top = tester.getTopLeft(find.text('我的')).dy;
    expect(top, lessThan(80), reason: '「我的」标题应顶对齐（实际 dy=$top）');
  });
}
