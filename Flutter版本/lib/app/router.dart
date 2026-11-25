import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../features/care_solution/care_solution_page.dart';
import '../features/home/expiry_list_page.dart';
import '../features/home/home_page.dart';
import '../features/lens/lens_detail_page.dart';
import '../features/lens/lens_edit_page.dart';
import '../features/reminder/reminder_settings_page.dart';
import '../features/settings/notification_page.dart';
import '../features/settings/profile_page.dart';
import '../features/updater/update_page.dart';

/// 根导航 key：二级页面用它脱离 Shell、全屏显示。
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// 路由配置：底部主导航仅「首页」「我的」，其余为二级页面。
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomePage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfilePage()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/lens/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const LensEditPage(),
    ),
    GoRoute(
      path: '/lens/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => LensDetailPage(
        lensId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
      ),
    ),
    GoRoute(
      path: '/lens/:id/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          LensEditPage(lensId: int.tryParse(state.pathParameters['id'] ?? '')),
    ),
    GoRoute(
      path: '/expiry-list',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ExpiryListPage(),
    ),
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ReminderSettingsPage(),
    ),
    GoRoute(
      path: '/care',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CareSolutionPage(),
    ),
    GoRoute(
      path: '/update',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const UpdatePage(),
    ),
  ],
);

/// 主 Shell：FScaffold + FBottomNavigationBar 两 Tab。
class MainShell extends StatelessWidget {
  const MainShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      footer: FBottomNavigationBar(
        index: shell.currentIndex,
        onChange: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        children: const [
          FBottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: Text('首页'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: Text('我的'),
          ),
        ],
      ),
      child: shell,
    );
  }
}
