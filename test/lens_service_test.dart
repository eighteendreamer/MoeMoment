import 'package:flutter_test/flutter_test.dart';

import 'package:moe_moment/core/database/app_database.dart';
import 'package:moe_moment/core/date/date_service.dart';
import 'package:moe_moment/features/lens/lens_service.dart';
import 'package:moe_moment/features/lens/models/lens_specs.dart';
import 'package:moe_moment/features/updater/github_config.dart';
import 'package:moe_moment/features/updater/update_service.dart';

Lens _lens({
  int id = 1,
  String status = 'unopened',
  String? openedAt,
  String? packageExpiry,
  String? discardedAt,
}) {
  return Lens(
    id: id,
    brand: 'Olens',
    name: 'Scandi Hazel',
    cycleId: 1,
    colorScheme: 'Hazel',
    lensSpecs: null,
    status: status,
    openedAt: openedAt,
    packageExpiryDate: packageExpiry,
    discardedAt: discardedAt,
    note: null,
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );
}

final _monthCycle = LensCycle(
  id: 1,
  cycleName: '月抛',
  cycleUnit: 'month',
  cycleValue: 1,
  isBuiltin: true,
  sortOrder: 1,
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  final today = DateTime(2026, 11, 24);
  final service = LensService(dateService: DateService(today: today));

  group('状态与到期推导', () {
    test('未开封 + 无包装有效期：不推断到期日', () {
      final view = service.buildView(_lens(status: 'unopened'), _monthCycle);
      expect(view.expiryDate, isNull);
      expect(view.isExpired, isFalse);
    });

    test('未开封 + 包装有效期已过：动态计算为已过期', () {
      final view = service.buildView(
        _lens(status: 'unopened', packageExpiry: '2026-11-01'),
        _monthCycle,
      );
      expect(view.expiryDate, DateTime(2026, 11, 1));
      expect(view.isExpired, isTrue);
    });

    test('已开封：按开封日期 + 周期计算到期日', () {
      final view = service.buildView(
        _lens(status: 'opened', openedAt: '2026-11-01'),
        _monthCycle,
      );
      expect(view.expiryDate, DateTime(2026, 12, 1));
      expect(view.isExpired, isFalse);
    });

    test('已开封且包装有效期更早：取较早日期', () {
      final view = service.buildView(
        _lens(
          status: 'opened',
          openedAt: '2026-11-01',
          packageExpiry: '2026-11-20',
        ),
        _monthCycle,
      );
      expect(view.expiryDate, DateTime(2026, 11, 20));
      expect(view.isExpired, isTrue);
    });

    test('已开封且使用周期到期日更早：取周期到期日', () {
      final view = service.buildView(
        _lens(
          status: 'opened',
          openedAt: '2026-01-01',
          packageExpiry: '2027-12-31',
        ),
        _monthCycle,
      );
      expect(view.expiryDate, DateTime(2026, 2, 1));
    });

    test('已丢弃：不参与到期计算', () {
      final view = service.buildView(
        _lens(
          status: 'discarded',
          openedAt: '2026-01-01',
          discardedAt: '2026-01-15',
        ),
        _monthCycle,
      );
      expect(view.expiryDate, isNull);
      expect(view.isDiscarded, isTrue);
    });

    test('到期当天计算为已过期', () {
      final view = service.buildView(
        _lens(status: 'opened', openedAt: '2026-10-24'),
        _monthCycle,
      );
      expect(view.expiryDate, DateTime(2026, 11, 24));
      expect(view.isExpired, isTrue);
    });
  });

  group('统计口径', () {
    test('使用中 / 未开封 / 已过期 / 已丢弃不计入统计', () {
      final views = [
        // 使用中（已开封未到期）
        service.buildView(
          _lens(id: 1, status: 'opened', openedAt: '2026-11-20'),
          _monthCycle,
        ),
        // 已开封且已过期
        service.buildView(
          _lens(id: 2, status: 'opened', openedAt: '2026-10-01'),
          _monthCycle,
        ),
        // 未开封（无包装有效期，计入未开封）
        service.buildView(_lens(id: 3, status: 'unopened'), _monthCycle),
        // 未开封但包装有效期已过 → 已过期
        service.buildView(
          _lens(id: 4, status: 'unopened', packageExpiry: '2026-10-01'),
          _monthCycle,
        ),
        // 已丢弃：不参与统计
        service.buildView(
          _lens(id: 5, status: 'discarded', discardedAt: '2026-11-01'),
          _monthCycle,
        ),
      ];
      final stats = service.computeStats(views);
      expect(stats.inUse, 1);
      expect(stats.unopened, 1);
      expect(stats.expired, 2);
    });
  });

  group('LensSpecs JSON 编解码（键名大小写契约）', () {
    test('按需求约定的键名解析', () {
      const raw =
          '{"Lens_diameter": 14.2, "Colored_diameter": 13.2, "Moisture_content": 48, '
          '"Base_arc": 8.6, "Left_eye_prescription": -3.25, "right_eye_prescription": -3.5}';
      final specs = LensSpecs.tryParse(raw);
      expect(specs.lensDiameter, 14.2);
      expect(specs.coloredDiameter, 13.2);
      expect(specs.moistureContent, 48);
      expect(specs.baseArc, 8.6);
      expect(specs.leftEyePrescription, -3.25);
      expect(specs.rightEyePrescription, -3.5);
    });

    test('编码后保持原键名拼写', () {
      const specs = LensSpecs(lensDiameter: 14.2, moistureContent: 48);
      final json = specs.encode();
      expect(json, contains('Lens_diameter'));
      expect(json, contains('Moisture_content'));
      expect(json, isNot(contains('lens_diameter')));
    });

    test('字段允许缺失，不阻塞保存', () {
      final specs = LensSpecs.tryParse('{"Lens_diameter": 14.2}');
      expect(specs.lensDiameter, 14.2);
      expect(specs.baseArc, isNull);
      expect(specs.isEmpty, isFalse);
    });

    test('空文本 / 非法 JSON 返回空对象', () {
      expect(LensSpecs.tryParse(null).isEmpty, isTrue);
      expect(LensSpecs.tryParse('').isEmpty, isTrue);
      expect(LensSpecs.tryParse('not json').isEmpty, isTrue);
    });
  });

  group('版本比较（禁止纯字符串比较）', () {
    test('逐段数字比较', () {
      expect(VersionComparator.compare('1.2.3', '1.2.3'), 0);
      expect(VersionComparator.compare('1.2.4', '1.2.3'), 1);
      expect(VersionComparator.compare('1.10.0', '1.9.0'), 1);
      expect(VersionComparator.compare('1.0.0', '1.0.10'), -1);
    });

    test('忽略 v 前缀', () {
      expect(VersionComparator.isNewer('v1.1.0', '1.0.0'), isTrue);
    });

    test('位数不同时按段补齐比较', () {
      expect(VersionComparator.isNewer('1.0.0.1', '1.0.0'), isTrue);
      expect(VersionComparator.isNewer('1.0', '1.0.1'), isFalse);
    });
  });

  group('GitHub 配置与下载源', () {
    test('未配置仓库时标记待配置', () {
      const config = GithubConfig();
      expect(config.isConfigured, isFalse);
    });

    test('镜像仅白名单模板可用', () {
      const config = GithubConfig(
        owner: 'example',
        repo: 'moe_moment',
        mirrorWhitelist: ['https://mirror.example.com/{tag}/{asset}'],
      );
      final release = ReleaseInfo(
        tagName: 'v1.2.0',
        releaseNotes: '',
        publishedAt: null,
        androidAssetName: 'moe_moment-v1.2.0-android.apk',
        sha256AssetName: 'moe_moment-v1.2.0-android.apk.sha256',
      );
      final mirror = config.mirrorAssetUrl(
        'https://mirror.example.com/{tag}/{asset}',
        tag: release.tagName,
        asset: release.androidAssetName!,
      );
      expect(
        mirror,
        'https://mirror.example.com/v1.2.0/moe_moment-v1.2.0-android.apk',
      );
      expect(
        config.mirrorAssetUrl(
          'https://evil.com/{tag}/{asset}',
          tag: 'v1',
          asset: 'a',
        ),
        isNull,
      );
    });

    test('自动模式镜像优先且回退官方源', () {
      const config = GithubConfig(
        owner: 'example',
        repo: 'moe_moment',
        mirrorWhitelist: ['https://mirror.example.com/{tag}/{asset}'],
      );
      final release = ReleaseInfo(
        tagName: 'v1.2.0',
        releaseNotes: '',
        publishedAt: null,
        androidAssetName: 'app.apk',
        sha256AssetName: null,
      );
      expect(
        config.officialAssetUrl(tag: 'v1.2.0', asset: 'app.apk'),
        'https://github.com/example/moe_moment/releases/download/v1.2.0/app.apk',
      );
      final urls = _candidateSources(config, release, 'auto');
      expect(urls.first, 'mirror');
      expect(urls.last, 'official');
      final officialOnly = _candidateSources(config, release, 'official');
      expect(officialOnly, ['official']);
    });
  });
}

List<String> _candidateSources(
  GithubConfig config,
  ReleaseInfo release,
  String mode,
) {
  final service = UpdateService(config: config);
  return service
      .candidateUrls(release: release, mode: mode)
      .map((c) => c.$1)
      .toList();
}
