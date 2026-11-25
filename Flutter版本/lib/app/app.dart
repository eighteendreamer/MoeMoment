import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';

import 'router.dart';
import 'theme/app_theme.dart';

/// 应用根 Widget。
class MoeMomentApp extends StatelessWidget {
  const MoeMomentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.build();
    return MaterialApp.router(
      title: '美瞳管理',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.materialTheme(),
      localizationsDelegates: const [
        ...FLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        ...FLocalizations.supportedLocales,
      ],
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => FTheme(
        data: theme,
        child: FToaster(
          child: FTooltipGroup(
            // 桌面端默认会给可滚动区域显示灰色滚动条，样式与应用不协调，全局隐藏。
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: child ?? const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}
