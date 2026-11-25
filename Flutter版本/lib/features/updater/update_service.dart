import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'github_config.dart';

/// Release 信息（解析自 GitHub Releases API）。
class ReleaseInfo {
  const ReleaseInfo({
    required this.tagName,
    required this.releaseNotes,
    required this.publishedAt,
    required this.androidAssetName,
    required this.sha256AssetName,
  });

  final String tagName;
  final String releaseNotes;
  final DateTime? publishedAt;

  /// 平台匹配到的 Android 安装包 Asset 文件名。
  final String? androidAssetName;

  /// 发布元数据中的 SHA-256 校验文件 Asset（约定：`<安装包名>.sha256`）。
  final String? sha256AssetName;

  bool get isPrerelease => tagName.contains('-');
}

/// 下载进度。
class DownloadProgress {
  const DownloadProgress({required this.received, required this.total});

  final int received;
  final int total;

  double? get fraction => total <= 0 ? null : received / total;
}

/// 更新检查结果。
class UpdateCheckResult {
  const UpdateCheckResult({required this.currentVersion, this.latest});

  final String currentVersion;
  final ReleaseInfo? latest;

  bool get hasUpdate =>
      latest != null &&
      VersionComparator.isNewer(latest!.tagName, currentVersion);
}

/// 版本比较：按数字段比较，忽略前导 `v`，不允许纯字符串大小比较。
class VersionComparator {
  /// 返回 true 表示 [a] 严格新于 [b]。
  static bool isNewer(String a, String b) => compare(a, b) > 0;

  /// 1: a 新于 b；0: 相同；-1: a 旧于 b。
  static int compare(String a, String b) {
    final pa = _parse(a);
    final pb = _parse(b);
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      if (pa[i] != pb[i]) return pa[i] > pb[i] ? 1 : -1;
    }
    if (pa.length != pb.length) return pa.length > pb.length ? 1 : -1;
    return 0;
  }

  static List<int> _parse(String version) {
    var v = version.trim().toLowerCase();
    if (v.startsWith('v')) v = v.substring(1);
    // 忽略预发布后缀（如 -beta.1）。
    final core = v.split('-').first;
    return core.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }
}

/// 自动更新服务：检查、下载、校验与平台安装分流。
///
/// - 校验值必须来自发布元数据（`<asset>.sha256` Asset），不能拿下载文件
///   自身计算的值冒充校验。
/// - 镜像仅使用白名单；自动模式镜像失败回退官方源。
class UpdateService {
  UpdateService({this.config = const GithubConfig()});

  final GithubConfig config;
  final http.Client _client = http.Client();

  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// 检查最新 Release（releases/latest 自动排除预发布版本）。
  Future<UpdateCheckResult> checkForUpdate() async {
    final current = await currentVersion();
    if (!config.isConfigured) {
      throw StateError('GitHub 仓库尚未配置（owner/repo），请在配置中填写');
    }
    final response = await _client
        .get(
          Uri.parse('${config.releasesApiUrl}/latest'),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw HttpException('检查更新失败: HTTP ${response.statusCode}');
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final latest = _parseRelease(data);
    return UpdateCheckResult(currentVersion: current, latest: latest);
  }

  ReleaseInfo _parseRelease(Map<String, dynamic> data) {
    final assets = (data['assets'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((a) => (a['name'] as String?) ?? '')
        .toList();
    final androidRegex = RegExp(config.androidAssetPattern);
    String? apk = assets.where(androidRegex.hasMatch).firstOrNull;
    String? checksum = apk == null
        ? null
        : assets.where((a) => a == '$apk.sha256').firstOrNull;
    return ReleaseInfo(
      tagName: (data['tag_name'] as String?) ?? '',
      releaseNotes: (data['body'] as String?) ?? '',
      publishedAt: DateTime.tryParse((data['published_at'] as String?) ?? ''),
      androidAssetName: apk,
      sha256AssetName: checksum,
    );
  }

  /// 生成候选下载地址（按模式），镜像仅取白名单模板。
  List<(String source, Uri url)> candidateUrls({
    required ReleaseInfo release,
    required String mode,
  }) {
    final asset = release.androidAssetName;
    if (asset == null) return const [];
    final tag = release.tagName;
    final official = (
      'official',
      Uri.parse(config.officialAssetUrl(tag: tag, asset: asset)),
    );
    switch (mode) {
      case 'official':
        return [official];
      case 'mirror':
        return [
          for (final template in config.mirrorWhitelist)
            (
              'mirror',
              Uri.parse(
                config.mirrorAssetUrl(template, tag: tag, asset: asset)!,
              ),
            ),
        ];
      case 'auto':
      default:
        final mirrors = [
          for (final template in config.mirrorWhitelist)
            (
              'mirror',
              Uri.parse(
                config.mirrorAssetUrl(template, tag: tag, asset: asset)!,
              ),
            ),
        ];
        return [...mirrors, official]; // 自动模式：镜像优先，失败回退官方源。
    }
  }

  /// 下载安装包并校验 SHA-256。失败时抛出异常。
  ///
  /// 预期校验值来自 Release 中的 `<asset>.sha256` 文件；缺少校验文件时
  /// 抛错拒绝安装，不能拿下载文件自身计算的值冒充校验。
  Future<DownloadedUpdate> download(
    ReleaseInfo release, {
    required String mode,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final asset = release.androidAssetName;
    if (asset == null) {
      throw StateError('最新 Release 中没有匹配 Android 平台的安装包');
    }

    // 预期校验值：从可信发布元数据获取。
    String? expectedSha256;
    for (final (_, url) in candidateUrls(release: release, mode: 'official')) {
      try {
        final resp = await _client
            .get(url)
            .timeout(const Duration(seconds: 30));
        if (resp.statusCode == 200) {
          expectedSha256 = resp.body.trim().split(' ').first.toLowerCase();
          break;
        }
      } catch (_) {
        // 校验文件拉取失败时继续，将在下方如实报告。
      }
    }

    final errors = <String>[];
    for (final (source, url) in candidateUrls(release: release, mode: mode)) {
      try {
        final downloaded = await _downloadFile(url, onProgress: onProgress);
        final actual = sha256.convert(downloaded.bytes).toString();
        if (expectedSha256 == null || expectedSha256.isEmpty) {
          throw StateError('发布元数据缺少 SHA-256 校验文件，无法完成校验');
        }
        if (actual != expectedSha256) {
          throw StateError('SHA-256 校验失败（来源: $source）');
        }
        return DownloadedUpdate(
          file: downloaded.file,
          source: source,
          sha256: actual,
        );
      } catch (e) {
        errors.add('$source: $e');
      }
    }
    throw StateError('下载失败：\n${errors.join('\n')}');
  }

  Future<({File file, List<int> bytes})> _downloadFile(
    Uri url, {
    void Function(DownloadProgress)? onProgress,
  }) async {
    final request = http.Request('GET', url);
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw HttpException('下载失败: HTTP ${response.statusCode}');
    }
    final total = response.contentLength ?? 0;
    final builder = BytesBuilder(copy: false);
    var received = 0;
    await for (final chunk in response.stream) {
      builder.add(chunk);
      received += chunk.length;
      if (onProgress != null) {
        onProgress(DownloadProgress(received: received, total: total));
      }
    }
    final bytes = builder.takeBytes();
    final tempDir = await Directory.systemTemp.createTemp('moe_moment_update');
    final file = File('${tempDir.path}${Platform.pathSeparator}update.apk');
    await file.writeAsBytes(bytes, flush: true);
    return (file: file, bytes: bytes);
  }

  void dispose() => _client.close();
}

/// 下载并校验通过后的更新包。
class DownloadedUpdate {
  const DownloadedUpdate({
    required this.file,
    required this.source,
    required this.sha256,
  });

  final File file;
  final String source;
  final String sha256;
}
