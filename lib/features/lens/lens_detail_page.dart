import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/converters.dart';
import '../../features/lens/lens_repository.dart';
import '../../features/lens/lens_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 美瞳详情页：完整信息、照片、开封 / 丢弃 / 删除 / 编辑操作。
class LensDetailPage extends StatelessWidget {
  const LensDetailPage({required this.lensId, super.key});

  final int lensId;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return StreamBuilder(
      stream: services.lensRepository.watchLens(lensId),
      builder: (context, snapshot) {
        final detail = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ResponsiveContent(
              maxWidth: 720,
              child: detail == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _DetailBody(detail: detail),
            ),
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final LensDetail detail;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final view = services.lensService.buildView(detail.lens, detail.cycle);
    final specs = view.specs;
    final status = LensStatus.fromDb(detail.lens.status);

    return ListView(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
            Expanded(
              child: Text(
                '美瞳详情',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => context.push('/lens/${detail.lens.id}/edit'),
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            ),
          ],
        ),

        // 图片区
        if (detail.images.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.lens_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: detail.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final img = detail.images[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(img.imagePath),
                    width: 220,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 220,
                      height: 180,
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // 基本信息
        _infoCard(
          children: [
            _row('品牌', detail.lens.brand),
            _row('名称', detail.lens.name),
            _row(
              '周期',
              '${detail.cycle.cycleName}（${detail.cycle.cycleValue}${_unitLabel(detail.cycle.cycleUnit)}）',
            ),
            if ((view.lens.colorScheme ?? '').isNotEmpty)
              _row('颜色方案', view.lens.colorScheme!),
            Row(
              children: [
                const SizedBox(
                  width: 88,
                  child: Text(
                    '状态',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                StatusChip.status(status),
                if (view.expiryDate != null) ...[
                  const SizedBox(width: 8),
                  DueChip(
                    expiryDate: view.expiryDate,
                    daysRemaining: view.daysRemaining,
                  ),
                ],
              ],
            ),
            if (view.expiryDate != null)
              _row('到期日期', DateIsoConverter.encode(view.expiryDate!)),
            if (detail.lens.openedAt != null)
              _row('开封日期', detail.lens.openedAt!),
            if (detail.lens.packageExpiryDate != null)
              _row('包装有效期', detail.lens.packageExpiryDate!),
            if ((view.lens.note ?? '').isNotEmpty) _row('备注', view.lens.note!),
          ],
        ),

        // 镜片参数
        if (!specs.isEmpty)
          _infoCard(
            title: '镜片参数（Lens Specs）',
            children: [
              if (specs.lensDiameter != null)
                _row('镜片直径', '${specs.lensDiameter} mm'),
              if (specs.coloredDiameter != null)
                _row('染色直径', '${specs.coloredDiameter} mm'),
              if (specs.moistureContent != null)
                _row('含水量', '${specs.moistureContent}%'),
              if (specs.baseArc != null) _row('基弧', '${specs.baseArc} mm'),
              if (specs.leftEyePrescription != null)
                _row('左眼度数', '${specs.leftEyePrescription}'),
              if (specs.rightEyePrescription != null)
                _row('右眼度数', '${specs.rightEyePrescription}'),
            ],
          ),

        // 操作区
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _Actions(detail: detail, view: view),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoCard({String? title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.detail, required this.view});

  final LensDetail detail;
  final LensView view;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final status = LensStatus.fromDb(detail.lens.status);
    final isDiscarded = view.isDiscarded;

    return Column(
      children: [
        if (status == LensStatus.unopened && !isDiscarded)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _confirmOpen(context, services),
              icon: const Icon(Icons.open_in_new),
              label: const Text('开始使用 / 标记开封'),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (!isDiscarded)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _confirmDiscard(context, services),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('标记丢弃'),
                ),
              ),
            if (!isDiscarded) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _confirmDelete(context, services),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('删除'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmOpen(BuildContext context, AppServices services) async {
    var selected = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          '确认开封',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '开封日期（默认当天）',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selected,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) selected = picked;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(DateIsoConverter.encode(selected)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '确认开封',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await services.lensRepository.openLens(detail.lens.id, selected);
    await services.reminders.resyncAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已开封')));
    }
  }

  Future<void> _confirmDiscard(
    BuildContext context,
    AppServices services,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          '标记丢弃',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '丢弃后将不再计入使用中、未开封与已过期统计，也不继续安排到期提醒。确认丢弃吗？',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '确认丢弃',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await services.lensRepository.discardLens(detail.lens.id, DateTime.now());
    await services.reminders.resyncAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已标记丢弃')));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppServices services,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          '删除美瞳',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '删除后不可恢复，关联照片将一并删除。确认删除吗？',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 先数据库提交（级联删除图片记录），成功后清理文件。
    final imagePaths = await services.lensRepository.deleteLens(detail.lens.id);
    for (final path in imagePaths) {
      try {
        await services.imageStorage.deletePersistent(path);
      } catch (_) {
        // 文件清理失败不影响数据库结果，避免误删范围外文件。
      }
    }
    await services.reminders.resyncAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已删除')));
      context.pop();
    }
  }
}

String _unitLabel(String unit) => switch (unit) {
  'day' => '天',
  'week' => '周',
  'month' => '月',
  'year' => '年',
  _ => unit,
};
