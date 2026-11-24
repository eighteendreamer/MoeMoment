import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:moe_moment/app/app_services.dart';
import 'package:moe_moment/core/database/app_database.dart';
import 'package:moe_moment/features/home/home_page.dart';

void main() {
  testWidgets('首页：空数据展示空状态与统计，添加按钮存在', (tester) async {
    // 使用内存数据库，避免测试依赖真实设备目录。
    final db = AppDatabase(NativeDatabase.memory());
    final services = AppServices(db: db);
    // 放大测试视口，确保懒加载的 Sliver 内容全部构建。
    await tester.binding.setSurfaceSize(const Size(800, 2200));

    await tester.pumpWidget(
      Provider.value(
        value: services,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 首页固定顺序区域标题。
    expect(find.text('美瞳管理'), findsWidgets);
    expect(find.text('即将到期'), findsOneWidget);
    expect(find.text('我的美瞳'), findsOneWidget);
    expect(find.text('美瞳统计'), findsOneWidget);
    expect(find.text('美瞳列表'), findsOneWidget);

    // 空数据统计为 0。
    expect(find.text('使用中'), findsOneWidget);
    expect(find.text('未开封'), findsOneWidget);
    expect(find.text('已过期'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));

    // 右下角悬浮添加按钮。
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
    services.updater.dispose();
    await db.close();
  });
}
