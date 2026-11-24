import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../core/date/date_service.dart';
import '../../features/lens/lens_repository.dart';
import '../../features/lens/lens_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 到期美瞳列表：查看全部即将到期或已过期美瞳。
class ExpiryListPage extends StatelessWidget {
  const ExpiryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return StreamBuilder<List<LensWithMeta>>(
      stream: services.lensRepository.watchAllLenses(),
      builder: (context, snapshot) {
        final views = (snapshot.data ?? const <LensWithMeta>[])
            .map(
              (item) => services.lensService.buildView(
                item.lens,
                item.cycle,
                coverImagePath: item.coverImagePath,
              ),
            )
            .toList();
        final relevant =
            views.where((v) => !v.isDiscarded && v.expiryDate != null).toList()
              ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

        final expiringSoon = relevant
            .where((v) => !const DateService().isExpired(v.expiryDate!))
            .toList();
        final expired = relevant
            .where((v) => const DateService().isExpired(v.expiryDate!))
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ResponsiveContent(
              maxWidth: 720,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '到期美瞳',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: '即将到期',
                          icon: Icons.schedule_rounded,
                        ),
                        if (expiringSoon.isEmpty)
                          const EmptyState(
                            message: '暂无即将到期的美瞳',
                            icon: Icons.event_available_outlined,
                          )
                        else
                          ...expiringSoon.map((v) => _card(context, v)),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: '已过期',
                          icon: Icons.error_outline,
                        ),
                        if (expired.isEmpty)
                          const EmptyState(
                            message: '没有已过期的美瞳',
                            icon: Icons.verified_outlined,
                          )
                        else
                          ...expired.map((v) => _card(context, v)),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, LensView v) {
    return GestureDetector(
      onTap: () => context.push('/lens/${v.lens.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            LensThumbnail(path: v.coverImagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.lens.brand} · ${v.lens.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${v.cycle.cycleName} · 到期 ${_fmt(v.expiryDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            DueChip(expiryDate: v.expiryDate, daysRemaining: v.daysRemaining),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime? date) {
  if (date == null) return '—';
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}
