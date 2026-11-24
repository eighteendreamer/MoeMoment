import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.card],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.lens,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '美瞳管理',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '更好管理你的美瞳与护理计划',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.notifications_outlined,
                  title: '系统通知',
                  subtitle: '通知权限与应用内通知开关',
                  onTap: () => context.push('/notifications'),
                ),
                _MenuTile(
                  icon: Icons.alarm_outlined,
                  title: '提醒设置',
                  subtitle: '三类提醒独立配置（点击「提醒设置」进入）',
                  onTap: () => context.push('/reminders'),
                ),
                _MenuTile(
                  icon: Icons.water_drop_outlined,
                  title: '护理液信息',
                  subtitle: '维护护理液品牌、开封日期和有效期',
                  onTap: () => context.push('/care'),
                ),
                _MenuTile(
                  icon: Icons.system_update_outlined,
                  title: '自动更新',
                  subtitle: '检查版本、下载校验和安装引导',
                  trailing: updateConfigured
                      ? null
                      : const _PendingTag(text: '待配置'),
                  onTap: () => context.push('/update'),
                ),
                _MenuTile(
                  icon: Icons.cloud_download_outlined,
                  title: 'GitHub 镜像加速',
                  subtitle: '下载源：官方 / 镜像 / 自动（在自动更新中设置）',
                  onTap: () => context.push('/update'),
                ),
                _MenuTile(
                  icon: Icons.info_outline,
                  title: '当前版本',
                  subtitle: _version.isEmpty ? '…' : _version,
                  onTap: () => context.push('/update'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}

class _PendingTag extends StatelessWidget {
  const _PendingTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
