import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../features/lens/lens_service.dart';

/// 响应式内容容器：限制最大宽度，适配平板与宽屏。
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.maxWidth = 720,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 区域标题行（标题 + 可选的「查看全部」动作）。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 状态标签：颜色 + 文字双通道表达，不单靠颜色。
class StatusChip extends StatelessWidget {
  const StatusChip.status(this.status, {super.key})
    : text = null,
      color = null,
      background = null;

  const StatusChip.label(this.text, this.color, this.background, {super.key})
    : status = null;

  final LensStatus? status;
  final String? text;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      LensStatus.unopened => (
        '未开封',
        AppColors.textSecondary,
        AppColors.divider,
      ),
      LensStatus.opened => ('使用中', AppColors.success, AppColors.successBg),
      LensStatus.discarded => (
        '已丢弃',
        AppColors.textSecondary,
        AppColors.divider,
      ),
      null => (
        text ?? '',
        color ?? AppColors.textSecondary,
        background ?? AppColors.divider,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 到期状态标签（即将到期 / 今天到期 / 已过期）。
class DueChip extends StatelessWidget {
  const DueChip({
    required this.expiryDate,
    required this.daysRemaining,
    super.key,
  });

  final DateTime? expiryDate;
  final int? daysRemaining;

  @override
  Widget build(BuildContext context) {
    if (expiryDate == null || daysRemaining == null) {
      return const SizedBox.shrink();
    }
    final days = daysRemaining!;
    if (days <= 0) {
      return const StatusChip.label(
        '已过期',
        AppColors.danger,
        AppColors.dangerBg,
      );
    }
    if (days == 1) {
      return const StatusChip.label(
        '今天到期',
        AppColors.warning,
        AppColors.warningBg,
      );
    }
    return StatusChip.label(
      '剩 $days 天',
      AppColors.warning,
      AppColors.warningBg,
    );
  }
}

/// 空状态视图。
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 统计卡片。
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 镜片缩略图（无图时显示占位图标，不用假图）。
class LensThumbnail extends StatelessWidget {
  const LensThumbnail({this.path, this.size = 48, this.radius = 12, super.key});

  final String? path;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = path != null && File(path!).existsSync()
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.file(
              File(path!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            ),
          )
        : _placeholder();
    return image;
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(
      Icons.lens_outlined,
      size: size * 0.5,
      color: AppColors.primary,
    ),
  );
}
