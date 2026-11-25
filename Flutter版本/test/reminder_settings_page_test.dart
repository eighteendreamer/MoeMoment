import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

import 'package:moe_moment/app/app_services.dart';
import 'package:moe_moment/app/theme/app_theme.dart';
import 'package:moe_moment/core/database/app_database.dart';
import 'package:moe_moment/features/reminder/reminder_settings_page.dart';

void main() {
  testWidgets('提醒设置页：标题行开关，关闭后选项区收起为提示', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final services = AppServices(db: db);
    await tester.binding.setSurfaceSize(const Size(800, 1600));

    await tester.pumpWidget(
      Provider.value(
        value: services,
        child: FTheme(
          data: AppTheme.build(),
          child: MaterialApp(home: ReminderSettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 三张卡片标题。
    expect(find.text('美瞳到期提醒'), findsOneWidget);
    expect(find.text('护理液更换提醒'), findsOneWidget);
    expect(find.text('护理液到期提醒'), findsOneWidget);

    // 默认美瞳到期提醒开启：选项可见，无关闭提示。
    // AnimatedCrossFade 会保留隐藏子树，用 hitTestable 只匹配可见节点。
    expect(find.text('提前天数').hitTestable(), findsNWidgets(2));
    expect(find.text('提醒已关闭，开启后按所选时间安排通知。').hitTestable(), findsNothing);

    // 关闭美瞳到期提醒开关：该卡片选项收起，出现提示文案。
    // 卡片按美瞳到期 → 护理液更换 → 护理液到期顺序构建，第一个开关即美瞳卡片。
    await tester.tap(find.byType(FSwitch).first);
    await tester.pumpAndSettle();

    expect(find.text('提醒已关闭，开启后按所选时间安排通知。').hitTestable(), findsOneWidget);
    // 关闭后对应的「提醒时间」选项不再显示（护理液两张卡仍开启）。
    expect(find.text('提醒时间').hitTestable(), findsNWidgets(2));

    // 自定义更换频率弹窗使用 ForUI 的 FTextField。
    await tester.tap(find.text('自定义').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('自定义更换频率'), findsOneWidget);
    expect(find.byType(FTextField), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    // 推进时钟，消化开关切换后调度链路中残留的延时任务。
    await tester.pump(const Duration(seconds: 10));
    // 显式释放资源，避免 drift 流去抖 Timer 在卸载后仍挂起。
    services.updater.dispose();
    await db.close();
  });
}
