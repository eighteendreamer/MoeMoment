import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import 'package:moe_moment/app/app_services.dart';
import 'package:moe_moment/app/theme/app_theme.dart';
import 'package:moe_moment/core/database/app_database.dart';
import 'package:moe_moment/features/lens/lens_edit_page.dart';

void main() {
  testWidgets('编辑页：镜片参数默认收起，点击标题可展开', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final services = AppServices(db: db);
    // 放大视口，保证下方卡片已构建。
    await tester.binding.setSurfaceSize(const Size(800, 2400));

    await tester.pumpWidget(
      Provider.value(
        value: services,
        child: FTheme(
          data: AppTheme.build(),
          child: const MaterialApp(home: LensEditPage()),
        ),
      ),
    );
    // drift 的查询需要真实事件循环时间，用 runAsync 等待首屏加载完成。
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (find.text('镜片参数').evaluate().isNotEmpty) break;
    }

    expect(find.text('镜片参数'), findsOneWidget);
    // 收起时展示摘要副标题。
    expect(find.text('选填 · 直径、含水量、基弧与度数'), findsOneWidget);
    final collapsedY = tester.getTopLeft(find.text('照片')).dy;

    // 点击卡片标题展开：后续卡片被向下推，参数区可见。
    await tester.tap(find.text('镜片参数'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final expandedY = tester.getTopLeft(find.text('照片')).dy;
    expect(expandedY, greaterThan(collapsedY + 100));
    expect(find.text('镜片直径 (mm)'), findsOneWidget);
    expect(find.text('右眼度数'), findsOneWidget);

    // 再次点击收起：高度回到初始。
    await tester.tap(find.text('镜片参数'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(find.text('照片')).dy, collapsedY);

    await tester.binding.setSurfaceSize(null);
    services.updater.dispose();
    await db.close();
  });
}
