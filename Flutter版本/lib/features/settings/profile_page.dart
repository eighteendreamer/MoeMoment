import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/common_widgets.dart';

/// 「我的」页面：系统通知、提醒设置、自动更新、GitHub 镜像加速、当前版本。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _version = '';
  bool _autoUpdate = true;
  bool _mirror = true;
  bool _flagsLoaded = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flagsLoaded) return;
    _flagsLoaded = true;
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    final services = AppServicesScope.of(context);
    final auto = await services.careService.getSetting('auto_update_check');
    final mode = await services.careService.getSetting('github_mirror_mode');
    if (!mounted) return;
    setState(() {
      _autoUpdate = auto == null || auto == 'true';
      _mirror = (mode ?? 'auto') != 'official';
    });
  }

  Future<void> _setAutoUpdate(bool value) async {
    setState(() => _autoUpdate = value);
    await AppServicesScope.of(context).careService
        .setSetting('auto_update_check', value ? 'true' : 'false');
  }

  Future<void> _setMirror(bool value) async {
    setState(() => _mirror = value);
    await AppServicesScope.of(context).careService
        .setSetting('github_mirror_mode', value ? 'auto' : 'official');
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final updateConfigured = services.updater.config.isConfigured;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContent(
            maxWidth: 720,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '我的',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildHeroCard(),
                const SizedBox(height: 12),
                _buildSettingsCard(updateConfigured: updateConfigured),
                _buildVersionCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 品牌头部卡片
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAD6E4), Color(0xFFFFF4F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            top: -4,
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          Positioned(
            right: 34,
            top: 26,
            child: Icon(
              Icons.auto_awesome,
              size: 10,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 0,
            child: Icon(
              Icons.auto_awesome,
              size: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.5),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/branding/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '美瞳管理',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '更好地管理你的美瞳与护理计划',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 系统与偏好分组卡片
  Widget _buildSettingsCard({required bool updateConfigured}) {
    return _GroupCard(
      children: [
        _SettingRow(
          icon: Icons.notifications_none_rounded,
          title: '系统通知',
          onTap: () => context.push('/notifications'),
        ),
        const _InsetDivider(),
        _SettingRow(
          icon: Icons.notifications_active_outlined,
          title: '提醒设置',
          onTap: () => context.push('/reminders'),
        ),
        const _InsetDivider(),
        _SettingRow(
          icon: Icons.autorenew_rounded,
          title: '自动更新',
          badge: updateConfigured ? null : const _PendingTag(text: '待配置'),
          onTap: () => context.push('/update'),
          trailing: FSwitch(value: _autoUpdate, onChange: _setAutoUpdate),
        ),
        const _InsetDivider(),
        _SettingRow(
          icon: Icons.code_rounded,
          title: 'GitHub 镜像加速',
          onTap: () => context.push('/update'),
          trailing: FSwitch(value: _mirror, onChange: _setMirror),
        ),
      ],
    );
  }

  // 版本信息卡片
  Widget _buildVersionCard() {
    return _GroupCard(
      children: [
        _SettingRow(
          icon: Icons.info_outline_rounded,
          title: '当前版本',
          onTap: () => context.push('/update'),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _version.isEmpty ? '…' : _version,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 大圆角白色分组卡片。
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// 分组内的设置行：左图标 + 标题（可带角标）+ 右侧尾部控件。
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.badge,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 21, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (badge != null) ...[const SizedBox(width: 6), badge!],
            const Spacer(),
            trailing ??
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

/// 分组内分割线：左侧缩进对齐文字起始位置。
class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 47,
      endIndent: 14,
      color: AppColors.divider,
    );
  }
}

class _PendingTag extends StatelessWidget {
  const _PendingTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
