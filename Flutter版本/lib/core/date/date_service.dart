import '../database/converters.dart';

/// 到期判定结果。
enum LensDueState { upcoming, expiringSoon, expired }

/// 集中的日期计算服务。
///
/// 到期日、提前提醒日、剩余天数与状态映射的唯一可信实现。
/// 所有计算基于本地日历日期；允许通过 [today] 注入当前日期以便测试。
class DateService {
  // ignore: prefer_initializing_formals
  const DateService({DateTime? today}) : _today = today;

  final DateTime? _today;

  /// 当前本地日历日期（去掉时间部分）。
  DateTime today() => DateIsoConverter.toLocalDate(_today ?? DateTime.now());

  /// 按周期计算到期日。
  ///
  /// - 日、周按自然日计算。
  /// - 月、年按自然月、自然年计算；月末或闰年无对应日期时截断到目标月份最后一天。
  DateTime expiryDateFrom({
    required DateTime openedDate,
    required String cycleUnit,
    required int cycleValue,
  }) {
    if (cycleValue <= 0) {
      throw ArgumentError.value(cycleValue, 'cycleValue', '周期数值必须为正整数');
    }
    final base = DateIsoConverter.toLocalDate(openedDate);
    switch (cycleUnit) {
      case 'day':
        return base.add(Duration(days: cycleValue));
      case 'week':
        return base.add(Duration(days: 7 * cycleValue));
      case 'month':
        return _addMonths(base, cycleValue);
      case 'year':
        return _addMonths(base, 12 * cycleValue);
      default:
        throw ArgumentError.value(cycleUnit, 'cycleUnit', '不支持的周期单位');
    }
  }

  /// 月末 / 闰年截断的加月实现。1 月 31 日 + 1 月 = 2 月最后一天；
  /// 闰年 2 月 29 日 + 1 年 = 次年 2 月 28 日。
  DateTime _addMonths(DateTime base, int months) {
    final year = base.year + (base.month - 1 + months) ~/ 12;
    final month = (base.month - 1 + months) % 12 + 1;
    final lastDay = _daysInMonth(year, month);
    final day = base.day > lastDay ? lastDay : base.day;
    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
      return isLeap ? 29 : 28;
    }
    return switch (month) {
      1 || 3 || 5 || 7 || 8 || 10 || 12 => 31,
      _ => 30,
    };
  }

  /// 提前提醒日：`expiryDate - advanceDays`。
  DateTime reminderDate({
    required DateTime expiryDate,
    required int advanceDays,
  }) {
    if (advanceDays < 0) {
      throw ArgumentError.value(advanceDays, 'advanceDays', '提前天数不能为负');
    }
    final expiry = DateIsoConverter.toLocalDate(expiryDate);
    return expiry.subtract(Duration(days: advanceDays));
  }

  /// 剩余天数（按本地自然日）；到期当天为 0，已过期为负数。
  int daysRemaining(DateTime expiryDate) {
    final expiry = DateIsoConverter.toLocalDate(expiryDate);
    return expiry.difference(today()).inDays;
  }

  /// `today >= expiryDate` 即为已过期；到期当天不能仍计入使用中。
  bool isExpired(DateTime expiryDate) => daysRemaining(expiryDate) <= 0;

  /// 「今天到期」仅是展示文案，不影响过期判定。
  bool isExpiringToday(DateTime expiryDate) => daysRemaining(expiryDate) == 0;

  /// 处于提前提醒窗口内（未过期，且剩余天数 <= advanceDays）。
  bool isExpiringSoon(DateTime expiryDate, int advanceDays) {
    final days = daysRemaining(expiryDate);
    return days > 0 && days <= advanceDays;
  }

  /// 汇总某个美瞳的到期状态。
  LensDueState dueState(DateTime expiryDate, int advanceDays) {
    if (isExpired(expiryDate)) return LensDueState.expired;
    if (isExpiringSoon(expiryDate, advanceDays)) {
      return LensDueState.expiringSoon;
    }
    return LensDueState.upcoming;
  }

  /// 护理液到期日：包装有效期与「开封日期 + 开封后有效天数」的较早值。
  /// 两个依据都不存在时返回 null，由界面提示用户补充，不得编造日期。
  DateTime? careSolutionExpiryDate({
    DateTime? packageExpiryDate,
    DateTime? openedAt,
    int? afterOpenValidDays,
  }) {
    DateTime? fromPackage = packageExpiryDate == null
        ? null
        : DateIsoConverter.toLocalDate(packageExpiryDate);
    DateTime? fromOpen;
    if (openedAt != null &&
        afterOpenValidDays != null &&
        afterOpenValidDays > 0) {
      fromOpen = expiryDateFrom(
        openedDate: openedAt,
        cycleUnit: 'day',
        cycleValue: afterOpenValidDays,
      );
    }
    if (fromPackage == null) return fromOpen;
    if (fromOpen == null) return fromPackage;
    return fromPackage.isBefore(fromOpen) ? fromPackage : fromOpen;
  }
}
