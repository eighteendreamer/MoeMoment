import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../shared/widgets/common_widgets.dart';

/// 系统通知页：权限状态、应用内总开关、通知记录。
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with WidgetsBindingObserver {
  bool? _systemGranted;
  bool _masterEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 用户可能去系统设置切换权限后返回，回前台时重新查询真实状态。
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    final services = AppServicesScope.of(context);
    final granted = await services.notifications.isSystemPermissionGranted();
    final master = await services.careService.getSetting(
      'system_notifications_enabled',
    );
    if (!mounted) return;
    setState(() {
      _systemGranted = granted;
      _masterEnabled = master == 'true';
      _loading = false;
    });
  }

  Future<void> _toggleMaster(bool value) async {
    final services = AppServicesScope.of(context);
    if (value) {
      // 首次启用提醒时才请求权限。
      final granted = await services.notifications.requestPermission();
      if (!granted) {
        await services.careService.setSetting(
          'system_notifications_enabled',
          'false',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('系统未授予通知权限，请前往系统设置开启后再启用')),
          );
          _load();
        }
        return;
      }
      await services.careService.setSetting(
        'system_notifications_enabled',
        'true',
      );
      await services.reminders.resyncAll();
    } else {
      // 关闭总开关：取消所有待触发提醒。
      await services.careService.setSetting(
        'system_notifications_enabled',
        'false',
      );
      await services.notifications.cancelAll();
    }
    _load();
  }

  Future<void> _openSystemSettingsHint() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('若系统权限被关闭，请在系统设置 → 应用 → 美瞳管理 → 通知 中开启'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 720,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '系统通知',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '系统通知权限',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (_loading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          StatusChip.label(
                            _systemGranted == true ? '已授权' : '未授权',
                            _systemGranted == true
                                ? AppColors.success
                                : AppColors.danger,
                            _systemGranted == true
                                ? AppColors.successBg
                                : AppColors.dangerBg,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '数据库中的开关只表示使用意愿，真实权限以系统为准。',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_systemGranted != true) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openSystemSettingsHint,
                        child: const Text(
                          '前往系统设置开启',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '应用内通知总开关',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    '关闭后不再安排本应用的任何提醒，并取消所有待触发通知',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _masterEnabled,
                    onChanged: (v) => _toggleMaster(v),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: '近期通知记录',
                icon: Icons.receipt_long_outlined,
              ),
              // 记录列表独立滚动：顶部固定，不随列表带动。
              Expanded(
                child: StreamBuilder<List<NotificationLog>>(
                  stream: services.notifications.recentLogs(),
                  builder: (context, snapshot) {
                    final logs = snapshot.data ?? const <NotificationLog>[];
                    if (logs.isEmpty) {
                      return const EmptyState(
                        message: '暂无通知记录',
                        icon: Icons.notifications_none,
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          const _LogHeaderRow(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: logs.length,
                              itemBuilder: (context, index) => _LogRow(
                                log: logs[index],
                                showDivider: index > 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 数据列表表头。
class _LogHeaderRow extends StatelessWidget {
  const _LogHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: const Row(
        children: [
          Expanded(child: _LogColText('通知键', bold: true)),
          SizedBox(width: 10),
          SizedBox(width: 108, child: _LogColText('计划时间')),
          SizedBox(width: 8),
          SizedBox(width: 52, child: _LogColText('状态')),
        ],
      ),
    );
  }
}

/// 单条通知记录行。
class _LogRow extends StatelessWidget {
  const _LogRow({required this.log, required this.showDivider});

  final NotificationLog log;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(log.status);
    final colors = switch (log.status) {
      'scheduled' => (AppColors.primary, AppColors.primaryLight),
      'sent' => (AppColors.success, AppColors.successBg),
      'failed' => (AppColors.danger, AppColors.dangerBg),
      _ => (AppColors.textSecondary, AppColors.background),
    };

    return Column(
      children: [
        if (showDivider) Container(height: 1, color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  log.notificationKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 108,
                child: Text(
                  _fmtDate(log.scheduledDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: StatusChip.label(status, colors.$1, colors.$2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _statusLabel(String status) => switch (status) {
    'scheduled' => '已调度',
    'sent' => '已发送',
    'cancelled' => '已取消',
    'failed' => '失败',
    _ => status,
  };

  /// DateTime → 'yyyy-MM-dd HH:mm'（本地业务时间，固定列宽对齐）。
  static String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

/// 表头列文字。
class _LogColText extends StatelessWidget {
  const _LogColText(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    );
  }
}
