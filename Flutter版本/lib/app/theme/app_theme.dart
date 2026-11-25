import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// 淡粉色设计 token（需求起点，全 App 统一使用）。
class AppColors {
  const AppColors._();

  static const primary = Color(0xFFE9789A); // 主色
  static const primaryLight = Color(0xFFFCE8EF); // 主色浅背景
  static const background = Color(0xFFFFF7FA); // 页面背景
  static const card = Color(0xFFFFFFFF); // 卡片背景
  static const textPrimary = Color(0xFF3D3038); // 主文字
  static const textSecondary = Color(0xFF8B7D84); // 次级文字
  static const divider = Color(0xFFF1E5EA); // 分割线

  static const success = Color(0xFF6FBF8B); // 柔和绿色
  static const warning = Color(0xFFF0A35C); // 柔和橙色
  static const danger = Color(0xFFE56B6F); // 柔和红色

  static const successBg = Color(0xFFE7F4EC);
  static const warningBg = Color(0xFFFDF1E3);
  static const dangerBg = Color(0xFFFBE9E9);
}

/// 应用主题：基于 ForUI 默认主题定制淡粉色品牌色。
///
/// ForUI 0.27 使用公开构造 `FThemeData(touch:, colors:)` 创建自定义主题；
/// ForUI 组件遵循 FThemeData，Material 组件（对话框、日期选择器等）
/// 使用 [AppTheme.materialTheme] 保持同一套淡粉色视觉。
class AppTheme {
  const AppTheme._();

  static FThemeData build() {
    final base = FTheme.neutral.light.touch;
    final colors = base.colors.copyWith(
      primary: AppColors.primary,
      primaryForeground: Colors.white,
      secondary: AppColors.primaryLight,
      secondaryForeground: AppColors.textPrimary,
      muted: AppColors.primaryLight,
      mutedForeground: AppColors.textSecondary,
      destructive: AppColors.danger,
      destructiveForeground: Colors.white,
      error: AppColors.danger,
      errorForeground: Colors.white,
      card: AppColors.card,
      border: AppColors.divider,
      background: AppColors.background,
      foreground: AppColors.textPrimary,
    );
    return FThemeData(touch: true, colors: colors);
  }

  /// Material 组件使用的配套主题（日期选择器、对话框等）。
  static ThemeData materialTheme() {
    final scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.primaryLight,
      error: AppColors.danger,
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.card),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.card,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        width: 320,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
