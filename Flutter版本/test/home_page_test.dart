import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import 'package:moe_moment/app/app_services.dart';
import 'package:moe_moment/app/theme/app_theme.dart';
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
        child: FTheme(
          data: AppTheme.build(),
          child: MaterialApp(home: HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 原型图顺序：标题 → 即将到期 → 我的美瞳 → 美瞳统计 → 美瞳列表。
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('即将到期'), findsOneWidget);
    expect(find.text('我的美瞳'), findsOneWidget);
    expect(find.text('美瞳统计'), findsOneWidget);
    expect(find.text('美瞳列表'), findsOneWidget);
    expect(find.text('共 0 副'), findsOneWidget);

    // 空数据统计为 0。
    expect(find.text('使用中'), findsOneWidget);
    expect(find.text('未开封'), findsOneWidget);
    expect(find.text('已过期'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));

    // 右下角悬浮添加按钮。
    expect(find.byIcon(Icons.add), findsOneWidget);

    // 搜索框默认收起，点击搜索图标后展开。
    expect(find.text('搜索品牌或名称'), findsNothing);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('搜索品牌或名称'), findsOneWidget);

    // 「全部」下拉：展开后可选状态，选择后胶囊文案更新。
    expect(find.text('全部'), findsOneWidget);
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('未开封').last);
    await tester.pumpAndSettle();
    expect(find.text('全部'), findsNothing);
    expect(find.text('未开封'), findsNWidgets(2));

    await tester.binding.setSurfaceSize(null);
    services.updater.dispose();
    await db.close();
  });
}
