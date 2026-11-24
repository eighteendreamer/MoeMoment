import '../../core/database/app_database.dart';
import '../../core/database/converters.dart';
import '../../core/date/date_service.dart';
import 'models/lens_specs.dart';

/// 美瞳持久化状态。
enum LensStatus {
  unopened('unopened', '未开封'),
  opened('opened', '使用中'),
  discarded('discarded', '已丢弃');

  const LensStatus(this.dbValue, this.display);
  final String dbValue;
  final String display;

  static LensStatus fromDb(String? value) =>
      LensStatus.values.where((s) => s.dbValue == value).firstOrNull ??
      LensStatus.unopened;
}

/// 一副美瞳在业务层的完整视图：数据库记录 + 周期 + 封面图 + 动态到期信息。
class LensView {
  const LensView({
    required this.lens,
    required this.cycle,
    this.coverImagePath,
    this.expiryDate,
  });

  final Lens lens;
  final LensCycle cycle;
  final String? coverImagePath;

  /// 最终到期日：
  /// - 已开封：开封日期 + 周期，与包装有效期取较早者；
  /// - 未开封：包装有效期（未填写时不推断，返回 null）；
  /// - 已丢弃：null，不参与到期计算。
  final DateTime? expiryDate;

  bool get isDiscarded => lens.discardedAt != null;

  bool get isExpired {
    final date = expiryDate;
    return date != null && const DateService().isExpired(date);
  }

  int? get daysRemaining {
    final date = expiryDate;
    if (date == null) return null;
    return const DateService().daysRemaining(date);
  }

  LensSpecs get specs => LensSpecs.tryParse(lens.lensSpecs);
}

/// 美瞳业务规则与统计口径的单一可信实现。
class LensService {
  const LensService({DateService? dateService})
    : _dates = dateService ?? const DateService();

  final DateService _dates;

  /// 根据记录与周期推导业务视图。
  LensView buildView(Lens lens, LensCycle cycle, {String? coverImagePath}) {
    return LensView(
      lens: lens,
      cycle: cycle,
      coverImagePath: coverImagePath,
      expiryDate: computeExpiryDate(lens, cycle),
    );
  }

  /// 最终到期日计算。
  DateTime? computeExpiryDate(Lens lens, LensCycle cycle) {
    if (lens.discardedAt != null) return null;
    final status = LensStatus.fromDb(lens.status);
    final package = DateIsoConverter.tryParse(lens.packageExpiryDate);
    switch (status) {
      case LensStatus.unopened:
        // 未开封按包装有效期判断；未填写时不得推断。
        return package;
      case LensStatus.opened:
        final opened = DateIsoConverter.tryParse(lens.openedAt);
        if (opened == null) return package;
        final usageExpiry = _dates.expiryDateFrom(
          openedDate: opened,
          cycleUnit: cycle.cycleUnit,
          cycleValue: cycle.cycleValue,
        );
        if (package == null) return usageExpiry;
        return package.isBefore(usageExpiry) ? package : usageExpiry;
      case LensStatus.discarded:
        return null;
    }
  }

  /// 首页三分类统计口径：
  /// - 使用中：已开封、未丢弃、未到期；
  /// - 未开封：unopened 且包装有效期未过（未填写也计入未开封）；
  /// - 已过期：按日期动态计算；
  /// - 已丢弃不参与任何统计。
  LensStats computeStats(Iterable<LensView> views) {
    var inUse = 0;
    var unopened = 0;
    var expired = 0;
    for (final view in views) {
      if (view.isDiscarded) continue;
      final status = LensStatus.fromDb(view.lens.status);
      if (status == LensStatus.opened) {
        if (view.expiryDate != null && _dates.isExpired(view.expiryDate!)) {
          expired++;
        } else {
          inUse++;
        }
      } else if (status == LensStatus.unopened) {
        final package = DateIsoConverter.tryParse(view.lens.packageExpiryDate);
        if (package != null && _dates.isExpired(package)) {
          expired++;
        } else {
          unopened++;
        }
      }
    }
    return LensStats(inUse: inUse, unopened: unopened, expired: expired);
  }
}

class LensStats {
  const LensStats({
    required this.inUse,
    required this.unopened,
    required this.expired,
  });

  final int inUse;
  final int unopened;
  final int expired;
}
