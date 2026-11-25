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

class _HomeContentState extends State<_HomeContent>
    with TickerProviderStateMixin {
  String _search = '';
  LensStatus? _statusFilter;
  int? _cycleFilterId;
  List<LensCycle> _cycles = [];

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _showSearch = false;
  bool _fabShrunk = false;

  /// 入场交错动画：单段 350ms，段间隔 60ms，共 4 段。
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 530),
  )..forward();

  late final List<Animation<double>> _sectionAnims = List.generate(4, (i) {
    final start = (i * 60) / 530;
    final end = ((i * 60) + 350) / 530;
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  });

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppServicesScope.of(context);
    services.lensRepository.watchCycles().first.then((cycles) {
      if (mounted) setState(() => _cycles = cycles);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _entrance.dispose();
    super.dispose();
  }

  /// 列表下滑后轻微收起悬浮按钮。
  void _onScroll() {
    final shrunk = _scrollCtrl.hasClients && _scrollCtrl.offset > 40;
    if (shrunk != _fabShrunk) setState(() => _fabShrunk = shrunk);
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _cycleFilterId = null;
      _search = '';
      _searchCtrl.clear();
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

  bool get _hasFilter =>
      _search.isNotEmpty || _statusFilter != null || _cycleFilterId != null;

  String get _filterLabel {
    if (_statusFilter != null) {
      return switch (_statusFilter!) {
        LensStatus.opened => '使用中',
        LensStatus.unopened => '未开封',
        LensStatus.discarded => '已丢弃',
      };
    }
    final cycle = _cycles.where((c) => c.id == _cycleFilterId).firstOrNull;
    return cycle?.cycleName ?? '全部';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 720,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 12),
                  child: Center(
                    child: Text(
                      '首页',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _Entrance(
                  animation: _sectionAnims[0],
                  child: _buildExpiringCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: _Entrance(
                  animation: _sectionAnims[1],
                  child: _buildMyLensCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: _Entrance(
                  animation: _sectionAnims[2],
                  child: _buildStatsCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: _Entrance(
                  animation: _sectionAnims[3],
                  child: _buildListHeader(),
                ),
              ),
              _buildListSliver(),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: _fabShrunk ? 0.88 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: _Pressable(
          scale: 0.92,
          elastic: true,
          onTap: () => context.push('/lens/add'),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFF09AB2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  // 一、即将到期
  Widget _buildExpiringCard() {
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

        return _Card(
          child: Column(
            children: [
              _CardHeader(
                icon: Icons.notification_important_outlined,
                title: '即将到期',
                action: InkWell(
                  onTap: () => context.push('/expiry-list'),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '查看全部',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (upcoming.isEmpty)
                const _SlimEmpty(
                  message: '暂无即将到期的美瞳',
                  icon: Icons.event_available_outlined,
                )
              else
                ...upcoming.take(3).map((v) => _ExpiringRow(view: v)),
            ],
          ),
        );
      },
    );
  }

  // 二、我的美瞳
  Widget _buildMyLensCard() {
    final active = widget.views.where((v) => !v.isDiscarded).toList();
    const maxShown = 4;
    final shown = active.take(maxShown).toList();
    final overflow = active.length - shown.length;

    return _Card(
      child: Column(
        children: [
          _CardHeader(
            icon: Icons.visibility_outlined,
            title: '我的美瞳',
            action: InkWell(
              onTap: _clearFilters,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '共 ${active.length} 副',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            const _SlimEmpty(
              message: '还没有美瞳，点击右下角 + 添加',
              icon: Icons.add_circle_outline,
            )
          else
            Row(
              children: [
                for (final v in shown) ...[
                  _Pressable(
                    onTap: () => context.push('/lens/${v.lens.id}'),
                    child: LensThumbnail(
                      path: v.coverImagePath,
                      size: 52,
                      radius: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (overflow > 0)
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '+$overflow',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // 三、美瞳统计
  Widget _buildStatsCard() {
    return _Card(
      child: Column(
        children: [
          const _CardHeader(icon: Icons.bar_chart_rounded, title: '美瞳统计'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.play_arrow_rounded,
                  label: '使用中',
                  value: widget.stats.inUse,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  icon: Icons.inventory_2_outlined,
                  label: '未开封',
                  value: widget.stats.unopened,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(
                  icon: Icons.schedule_rounded,
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

  // 四、美瞳列表表头：标题 + 搜索图标 + 「全部」筛选
  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '美瞳列表',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _Pressable(
                onTap: () => setState(() => _showSearch = !_showSearch),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _showSearch
                        ? AppColors.primaryLight
                        : AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Icon(
                    Icons.search,
                    size: 17,
                    color: _showSearch
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FilterMenu(
                label: _filterLabel,
                active: _hasFilter,
                status: _statusFilter,
                cycleId: _cycleFilterId,
                cycles: _cycles,
                onStatus: (v) => setState(() => _statusFilter = v),
                onCycle: (v) => setState(() => _cycleFilterId = v),
                onClear: _clearFilters,
              ),
            ],
          ),
          if (_showSearch) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '搜索品牌或名称',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 五、美瞳列表
  Widget _buildListSliver() {
    final list = _filtered;
    final listKey = ValueKey('$_search|$_statusFilter|$_cycleFilterId');
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 88),
      sliver: SliverToBoxAdapter(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: widget.loading
              ? const Padding(
                  key: ValueKey('loading'),
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : list.isEmpty
              ? const EmptyState(
                  key: ValueKey('empty'),
                  message: '没有符合条件的美瞳',
                  icon: Icons.search_off,
                )
              : Column(
                  key: listKey,
                  children: [for (final v in list) _LensListCard(view: v)],
                ),
        ),
      ),
    );
  }
}

/// 白色圆角分组卡片。
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

/// 卡片标题行：图标 + 标题 + 右侧动作。
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

/// 统计小卡：图标 + 标签 + 数字滚动。
class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '$v',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「全部」筛选胶囊：状态与周期合并在一个下拉里。
class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.active,
    required this.status,
    required this.cycleId,
    required this.cycles,
    required this.onStatus,
    required this.onCycle,
    required this.onClear,
  });

  final String label;
  final bool active;
  final LensStatus? status;
  final int? cycleId;
  final List<LensCycle> cycles;
  final ValueChanged<LensStatus?> onStatus;
  final ValueChanged<int?> onCycle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.card),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(6),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.divider),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(180, 0)),
      ),
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        _menuItem('全部', active: !active, onPressed: onClear),
        const _MenuSectionLabel('状态'),
        _menuItem(
          '全部状态',
          active: status == null,
          onPressed: () => onStatus(null),
        ),
        _menuItem(
          '使用中',
          active: status == LensStatus.opened,
          onPressed: () => onStatus(LensStatus.opened),
        ),
        _menuItem(
          '未开封',
          active: status == LensStatus.unopened,
          onPressed: () => onStatus(LensStatus.unopened),
        ),
        const _MenuSectionLabel('周期'),
        _menuItem(
          '全部周期',
          active: cycleId == null,
          onPressed: () => onCycle(null),
        ),
        for (final c in cycles)
          _menuItem(
            '${c.cycleName}（${c.cycleValue}${_unitLabel(c.cycleUnit)}）',
            active: cycleId == c.id,
            onPressed: () => onCycle(c.id),
          ),
      ],
      builder: (context, controller, _) => _Pressable(
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primaryLight
                : AppColors.primaryLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 16,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
    String text, {
    required bool active,
    VoidCallback? onPressed,
  }) {
    return MenuItemButton(
      onPressed: onPressed,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        minimumSize: WidgetStatePropertyAll(Size(0, 34)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          if (active)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check, size: 15, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

/// 下拉分组标题。
class _MenuSectionLabel extends StatelessWidget {
  const _MenuSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 紧凑空状态提示。
class _SlimEmpty extends StatelessWidget {
  const _SlimEmpty({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 首次入场：淡入 + 轻微上移（16px）。
class _Entrance extends StatelessWidget {
  const _Entrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// 轻量按压反馈：按下缩放。
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onTap,
    required this.child,
    this.scale = 0.97,
    this.elastic = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final double scale;
  final bool elastic;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 100),
        curve: widget.elastic ? Curves.easeOutBack : Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 克制呼吸动效：0.95 ~ 1.05 缩放，周期 2s。
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.95,
    end: 1.05,
  ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: 0.82 + 0.18 * ((_scale.value - 0.95) / 0.1),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// 即将到期行：圆形缩略图 + 名称 + 到期文案。
class _ExpiringRow extends StatelessWidget {
  const _ExpiringRow({required this.view});

  final LensView view;

  @override
  Widget build(BuildContext context) {
    final days = view.daysRemaining;
    final expired = days != null && days <= 0;
    final dueToday = days == 1;
    final text = expired
        ? '已过期'
        : dueToday
        ? '今天到期'
        : '${(days ?? 1) - 1}天后到期';
    final chip = Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: expired ? AppColors.danger : AppColors.primary,
      ),
    );

    return _Pressable(
      onTap: () => context.push('/lens/${view.lens.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            LensThumbnail(path: view.coverImagePath, size: 36, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${view.lens.brand} · ${view.lens.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (dueToday) _Pulse(child: chip) else chip,
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
    final color = view.lens.colorScheme;
    final note = view.lens.note;
    final extra = [
      if ((color ?? '').isNotEmpty) '颜色: $color',
      if ((note ?? '').isNotEmpty) '备注: $note',
      if (view.expiryDate != null) '到期 ${_fmtDate(view.expiryDate!)}',
    ].join('  ·  ');

    return _Pressable(
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '周期: ${view.cycle.cycleName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusChip.status(status),
                      if (view.isExpired) ...[
                        const SizedBox(width: 4),
                        const StatusChip.label(
                          '已过期',
                          AppColors.danger,
                          AppColors.dangerBg,
                        ),
                      ],
                    ],
                  ),
                  if (extra.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        extra,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

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
