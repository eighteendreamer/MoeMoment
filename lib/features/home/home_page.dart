import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../features/lens/lens_repository.dart';
import '../../features/lens/lens_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 首页：即将到期 → 我的美瞳 → 美瞳统计 → 美瞳列表。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return StreamBuilder<List<LensWithMeta>>(
      stream: services.lensRepository.watchAllLenses(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <LensWithMeta>[];
        final views = items
            .map(
              (item) => services.lensService.buildView(
                item.lens,
                item.cycle,
                coverImagePath: item.coverImagePath,
              ),
            )
            .toList();
        final stats = services.lensService.computeStats(views);
        return _HomeContent(
          views: views,
          stats: stats,
          loading:
              snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null,
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.views,
    required this.stats,
    required this.loading,
  });

  final List<LensView> views;
  final LensStats stats;
  final bool loading;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _search = '';
  LensStatus? _statusFilter;
  int? _cycleFilterId;
  List<LensCycle> _cycles = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppServicesScope.of(context);
    services.lensRepository.watchCycles().first.then((cycles) {
      if (mounted) setState(() => _cycles = cycles);
    });
  }

  List<LensView> get _filtered {
    Iterable<LensView> list = widget.views;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where(
        (v) =>
            v.lens.brand.toLowerCase().contains(q) ||
            v.lens.name.toLowerCase().contains(q),
      );
    }
    if (_statusFilter != null) {
      final f = _statusFilter!;
      list = list.where((v) {
        return switch (f) {
          LensStatus.discarded => v.isDiscarded,
          LensStatus.opened =>
            !v.isDiscarded &&
                LensStatus.fromDb(v.lens.status) == LensStatus.opened &&
                !v.isExpired,
          LensStatus.unopened =>
            !v.isDiscarded &&
                LensStatus.fromDb(v.lens.status) == LensStatus.unopened &&
                !v.isExpired,
        };
      });
    }
    if (_cycleFilterId != null) {
      list = list.where((v) => v.lens.cycleId == _cycleFilterId);
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 720,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                  child: Row(
                    children: [
                      Icon(Icons.lens, color: AppColors.primary, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        '美瞳管理',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildExpiringSection()),
              SliverToBoxAdapter(child: _buildMyLensSection()),
              SliverToBoxAdapter(child: _buildStatsSection()),
              SliverToBoxAdapter(child: _buildListSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/lens/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 即将到期
  Widget _buildExpiringSection() {
    final services = AppServicesScope.of(context);
    return StreamBuilder<LensExpiryReminderSetting>(
      stream: services.careService.watchLensExpirySettings(),
      builder: (context, snapshot) {
        final advanceDays = snapshot.data?.advanceDays ?? 3;
        final today = DateTime.now();
        final upcoming =
            widget.views
                .where((v) => !v.isDiscarded && v.expiryDate != null)
                .where(
                  (v) => v.expiryDate!.isBefore(
                    today.add(Duration(days: advanceDays + 1)),
                  ),
                )
                .toList()
              ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              SectionHeader(
                title: '即将到期',
                icon: Icons.notification_important_outlined,
                actionLabel: '查看全部',
                onAction: () => context.push('/expiry-list'),
              ),
              if (upcoming.isEmpty)
                const EmptyState(
                  message: '暂无即将到期的美瞳',
                  icon: Icons.event_available_outlined,
                )
              else
                ...upcoming.take(3).map((v) => _ExpiringCard(view: v)),
            ],
          ),
        );
      },
    );
  }

  // 我的美瞳
  Widget _buildMyLensSection() {
    final thumbs = widget.views.where((v) => !v.isDiscarded).take(6).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          SectionHeader(
            title: '我的美瞳',
            icon: Icons.visibility_outlined,
            actionLabel:
                '共 ${widget.views.where((v) => !v.isDiscarded).length} 副',
            onAction: () => setState(() {
              _statusFilter = null;
              _cycleFilterId = null;
              _search = '';
            }),
          ),
          if (thumbs.isEmpty)
            const EmptyState(
              message: '还没有美瞳，点击右下角 + 添加',
              icon: Icons.add_circle_outline,
            )
          else
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: thumbs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => context.push('/lens/${thumbs[index].lens.id}'),
                  child: LensThumbnail(
                    path: thumbs[index].coverImagePath,
                    size: 64,
                    radius: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 美瞳统计
  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '美瞳统计', icon: Icons.bar_chart_rounded),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: '使用中',
                  value: widget.stats.inUse,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: '未开封',
                  value: widget.stats.unopened,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: '已过期',
                  value: widget.stats.expired,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 美瞳列表
  Widget _buildListSection() {
    final list = _filtered;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          const SectionHeader(title: '美瞳列表', icon: Icons.list_alt_rounded),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: '搜索品牌或名称',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _StatusFilterChip(
                  value: _statusFilter,
                  onChange: (v) => setState(() => _statusFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            key: ValueKey(_cycleFilterId),
            initialValue: _cycleFilterId,
            isDense: true,
            decoration: InputDecoration(
              labelText: '按周期筛选',
              isDense: true,
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('全部周期')),
              ..._cycles.map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    '${c.cycleName}（${c.cycleValue}${_unitLabel(c.cycleUnit)}）',
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _cycleFilterId = v),
          ),
          const SizedBox(height: 8),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (list.isEmpty)
            const EmptyState(message: '没有符合条件的美瞳', icon: Icons.search_off)
          else
            ...list.map((v) => _LensListCard(view: v)),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({required this.value, required this.onChange});

  final LensStatus? value;
  final void Function(LensStatus?) onChange;

  static const _options = [
    (null, '全部状态'),
    (LensStatus.opened, '使用中'),
    (LensStatus.unopened, '未开封'),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LensStatus?>(
      initialValue: value,
      isDense: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
      items: _options
          .map(
            (o) => DropdownMenuItem(
              value: o.$1,
              child: Text(o.$2, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: onChange,
    );
  }
}

class _ExpiringCard extends StatelessWidget {
  const _ExpiringCard({required this.view});

  final LensView view;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/lens/${view.lens.id}'),
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
            LensThumbnail(path: view.coverImagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${view.lens.brand} · ${view.lens.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${view.cycle.cycleName} · 到期 ${_fmt(view.expiryDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            DueChip(
              expiryDate: view.expiryDate,
              daysRemaining: view.daysRemaining,
            ),
          ],
        ),
      ),
    );
  }
}

class _LensListCard extends StatelessWidget {
  const _LensListCard({required this.view});

  final LensView view;

  @override
  Widget build(BuildContext context) {
    final status = LensStatus.fromDb(view.lens.status);
    return GestureDetector(
      onTap: () => context.push('/lens/${view.lens.id}'),
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
            LensThumbnail(path: view.coverImagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${view.lens.brand} · ${view.lens.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (view.isExpired)
                        const StatusChip.label(
                          '已过期',
                          AppColors.danger,
                          AppColors.dangerBg,
                        )
                      else
                        DueChip(
                          expiryDate: view.expiryDate,
                          daysRemaining: view.daysRemaining,
                        ),
                      StatusChip.status(status),
                      if ((view.lens.colorScheme ?? '').isNotEmpty)
                        StatusChip.label(
                          view.lens.colorScheme!,
                          AppColors.primary,
                          AppColors.primaryLight,
                        ),
                    ],
                  ),
                  if ((view.lens.note ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '备注：${view.lens.note}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime? date) => date == null ? '—' : _fmtDate(date);

String _fmtDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

String _unitLabel(String unit) => switch (unit) {
  'day' => '天',
  'week' => '周',
  'month' => '月',
  'year' => '年',
  _ => unit,
};
