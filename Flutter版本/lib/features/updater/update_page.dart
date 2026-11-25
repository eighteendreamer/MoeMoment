import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../app/app_services.dart';
import '../../app/theme/app_theme.dart';
import '../../features/updater/github_config.dart';
import '../../features/updater/update_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 自动更新页：检查版本、下载校验、平台安装引导、下载源设置。
class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  String _currentVersion = '';
  bool _checking = false;
  bool _downloading = false;
  double? _progress;
  ReleaseInfo? _latest;
  String? _message;
  String _mirrorMode = 'auto';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _currentVersionThen();
  }

  Future<void> _loadSettings() async {
    final services = AppServicesScope.of(context);
    final mode = await services.careService.getSetting('github_mirror_mode');
    if (mounted) setState(() => _mirrorMode = mode ?? 'auto');
    // 「我的」页的「自动更新」开关：开启时进入本页自动检查一次。
    final auto = await services.careService.getSetting('auto_update_check');
    if ((auto ?? 'true') == 'true' && mounted) {
      await _check();
    }
  }

  Future<void> _currentVersionThen() async {
    final services = AppServicesScope.of(context);
    try {
      final version = await services.updater.currentVersion();
      if (mounted) setState(() => _currentVersion = version);
    } catch (_) {
      if (mounted) setState(() => _currentVersion = '未知');
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    final services = AppServicesScope.of(context);
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      final result = await services.updater.checkForUpdate();
      setState(() {
        _latest = result.latest;
        _message = result.hasUpdate
            ? '发现新版本 ${result.latest!.tagName}'
            : '当前已是最新版本';
      });
    } catch (e) {
      setState(() => _message = '检查更新失败：$e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _downloadAndInstall() async {
    final services = AppServicesScope.of(context);
    if (_latest == null || _downloading) return;

    // 平台分流：普通 iOS App 不支持应用内自更新。
    if (Platform.isIOS) {
      final url = services.updater.config.iosStoreUrl;
      setState(() {
        _message = url.isEmpty
            ? 'iOS 更新需前往 App Store / TestFlight；分发渠道尚未配置（待配置项）。'
            : '请前往分发渠道完成更新：$url';
      });
      return;
    }
    if (!Platform.isAndroid) {
      setState(() => _message = '当前平台不支持应用内更新');
      return;
    }

    setState(() {
      _downloading = true;
      _progress = null;
      _message = null;
    });
    try {
      final downloaded = await services.updater.download(
        _latest!,
        mode: _mirrorMode,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p.fraction);
        },
      );
      setState(() {
        _message = '校验通过（${downloaded.source} 源），交给系统安装…';
      });
      final result = await OpenFilex.open(downloaded.file.path);
      if (mounted) {
        setState(() {
          _message = result.type == ResultType.done
              ? '请在系统安装界面确认安装（按 Android 版本可能需要允许安装未知应用）'
              : '无法启动安装：${result.message}';
        });
      }
    } catch (e) {
      setState(() => _message = '下载失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _setMode(String mode) async {
    final services = AppServicesScope.of(context);
    await services.careService.setSetting('github_mirror_mode', mode);
    setState(() => _mirrorMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final config = services.updater.config;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 720,
          child: ListView(
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
                      '自动更新',
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
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '当前版本',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _currentVersion.isEmpty ? '…' : 'v$_currentVersion',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: (_checking || _downloading) ? null : _check,
                        icon: _checking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_checking ? '检查中…' : '检查更新'),
                      ),
                    ),
                    if (!config.isConfigured) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '【待配置】GitHub 仓库 owner / repo、镜像地址尚未提供，'
                          '检查更新功能在配置完成前不可用。请在 lib/features/updater/github_config.dart 填写。',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_latest != null && config.isConfigured)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '最新版本：${_latest!.tagName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_latest!.releaseNotes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _latest!.releaseNotes,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: (_downloading)
                              ? null
                              : _downloadAndInstall,
                          icon: const Icon(Icons.download_outlined),
                          label: Text(_downloading ? '下载中…' : '下载并安装（Android）'),
                        ),
                      ),
                      if (_downloading && _progress != null) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: AppColors.primaryLight,
                          color: AppColors.primary,
                        ),
                        Text(
                          '${(_progress! * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '下载源（GitHub 镜像加速）',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: GithubConfig.sourceModes
                          .map(
                            (mode) => ChoiceChip(
                              label: Text(_modeLabel(mode)),
                              selected: _mirrorMode == mode,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: _mirrorMode == mode
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              backgroundColor: AppColors.background,
                              side: BorderSide(
                                color: _mirrorMode == mode
                                    ? AppColors.primary
                                    : AppColors.divider,
                              ),
                              onSelected: (_) => _setMode(mode),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      config.mirrorWhitelist.isEmpty
                          ? '镜像白名单为空：镜像 / 自动模式将直接使用官方源（镜像地址待配置）。'
                          : '镜像白名单：${config.mirrorWhitelist.join('、')}。自动模式下镜像失败回退官方源，校验不可跳过。',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              if (_message != null)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _message!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static String _modeLabel(String mode) => switch (mode) {
    'official' => '官方源',
    'mirror' => '镜像源',
    'auto' => '自动',
    _ => mode,
  };
}
