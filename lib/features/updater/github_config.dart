/// GitHub 更新源配置。
///
/// 【待配置】以下值尚未提供，当前为明确占位，不得臆造仓库地址或镜像服务：
/// - [owner] / [repo]：GitHub 仓库信息；
/// - [androidAssetPattern]：Android 安装包 Asset 的文件名匹配规则（正则）；
/// - [mirrorWhitelist]：可信镜像 URL 模板白名单，需包含 `{tag}` 与 `{asset}` 占位。
class GithubConfig {
  const GithubConfig({
    this.owner = '',
    this.repo = '',
    this.androidAssetPattern = r'moe_moment.*\.apk$',
    this.mirrorWhitelist = const [],
    this.iosStoreUrl = '',
  });

  final String owner;
  final String repo;

  /// 是否已完成最小可用配置。
  bool get isConfigured => owner.isNotEmpty && repo.isNotEmpty;

  String get releasesApiUrl =>
      'https://api.github.com/repos/$owner/$repo/releases';

  /// 下载源模式。
  static const sourceModes = ['official', 'mirror', 'auto'];

  /// Android 安装包 Asset 匹配规则。
  final String androidAssetPattern;

  /// 镜像 URL 模板白名单。
  final List<String> mirrorWhitelist;

  /// iOS 分发渠道（App Store / TestFlight），普通 App 不支持应用内自更新。
  final String iosStoreUrl;

  /// 官方 Asset 下载地址。
  String officialAssetUrl({required String tag, required String asset}) =>
      'https://github.com/$owner/$repo/releases/download/$tag/$asset';

  /// 镜像 Asset 下载地址（仅白名单内的模板可用）。
  String? mirrorAssetUrl(
    String mirrorTemplate, {
    required String tag,
    required String asset,
  }) {
    if (!mirrorWhitelist.contains(mirrorTemplate)) return null;
    if (!mirrorTemplate.contains('{tag}') ||
        !mirrorTemplate.contains('{asset}')) {
      return null;
    }
    return mirrorTemplate
        .replaceAll('{tag}', tag)
        .replaceAll('{asset}', Uri.encodeComponent(asset));
  }
}
