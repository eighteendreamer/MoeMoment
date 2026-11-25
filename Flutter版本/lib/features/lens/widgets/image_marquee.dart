import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// 多图跑马灯：三列固定比例 6:3:1，定时切换，支持点击切换。
class ImageMarquee extends StatefulWidget {
  const ImageMarquee({required this.paths, this.height = 180, super.key});

  final List<String> paths;
  final double height;

  @override
  State<ImageMarquee> createState() => _ImageMarqueeState();
}

class _ImageMarqueeState extends State<ImageMarquee> {
  Timer? _timer;
  int _start = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant ImageMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paths.length != widget.paths.length) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.paths.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _start = (_start + 1) % widget.paths.length);
    });
  }

  /// 点击切换：点主图前进一张；点副图把该图移到主位。
  void _onTap(int offset) {
    if (widget.paths.length <= 1) return;
    setState(() {
      _start = (_start + (offset == 0 ? 1 : offset)) % widget.paths.length;
    });
    // 手动切换后重新计时，避免紧接着又自动切一次。
    _restartTimer();
  }

  Widget _slot(int offset) {
    final index = (_start + offset) % widget.paths.length;
    final path = widget.paths[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(offset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 480),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.18, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          ),
          child: SizedBox.expand(
            key: ValueKey('${path}_$index'),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.primaryLight,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paths.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(Icons.lens_outlined, size: 56, color: AppColors.primary),
        ),
      );
    }
    if (widget.paths.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(height: widget.height, child: _slot(0)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: widget.height,
        child: Row(
          children: [
            Expanded(flex: 6, child: _slot(0)),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: _slot(1)),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: _slot(2)),
          ],
        ),
      ),
    );
  }
}
