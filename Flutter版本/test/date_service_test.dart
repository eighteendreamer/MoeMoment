import 'package:flutter_test/flutter_test.dart';

import 'package:moe_moment/core/date/date_service.dart';

void main() {
  // 固定「今天」，避免测试依赖真实系统时间。
  final service = DateService(today: DateTime(2026, 11, 24));

  group('周期到期日计算（自然日历）', () {
    test('日抛：1 天', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2026, 11, 10),
        cycleUnit: 'day',
        cycleValue: 1,
      );
      expect(expiry, DateTime(2026, 11, 11));
    });

    test('双周抛：2 周', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2026, 11, 10),
        cycleUnit: 'week',
        cycleValue: 2,
      );
      expect(expiry, DateTime(2026, 11, 24));
    });

    test('月抛：1 个月', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2026, 11, 10),
        cycleUnit: 'month',
        cycleValue: 1,
      );
      expect(expiry, DateTime(2026, 12, 10));
    });

    test('季抛：3 个月', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2026, 8, 24),
        cycleUnit: 'month',
        cycleValue: 3,
      );
      expect(expiry, DateTime(2026, 11, 24));
    });

    test('半年抛：6 个月', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2026, 5, 24),
        cycleUnit: 'month',
        cycleValue: 6,
      );
      expect(expiry, DateTime(2026, 11, 24));
    });

    test('年抛：1 年', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2025, 11, 24),
        cycleUnit: 'year',
        cycleValue: 1,
      );
      expect(expiry, DateTime(2026, 11, 24));
    });

    test('自定义周期：10 天', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2026, 11, 1),
        cycleUnit: 'day',
        cycleValue: 10,
      );
      expect(expiry, DateTime(2026, 11, 11));
    });

    test('月末加月：1 月 31 日 + 1 月 = 2 月最后一天（非闰年）', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2027, 1, 31),
        cycleUnit: 'month',
        cycleValue: 1,
      );
      expect(expiry, DateTime(2027, 2, 28));
    });

    test('月末加月：1 月 31 日 + 1 月 = 2 月 29 日（闰年）', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2028, 1, 31),
        cycleUnit: 'month',
        cycleValue: 1,
      );
      expect(expiry, DateTime(2028, 2, 29));
    });

    test('闰年 2 月 29 日 + 1 年 = 次年 2 月 28 日', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2028, 2, 29),
        cycleUnit: 'year',
        cycleValue: 1,
      );
      expect(expiry, DateTime(2029, 2, 28));
    });

    test('跨年加月：11 月 + 3 月 = 次年 2 月', () {
      final expiry = service.expiryDateFrom(
        openedDate: DateTime(2026, 11, 30),
        cycleUnit: 'month',
        cycleValue: 3,
      );
      expect(expiry, DateTime(2027, 2, 28));
    });

    test('非法周期数值抛出异常', () {
      expect(
        () => service.expiryDateFrom(
          openedDate: DateTime(2026, 11, 10),
          cycleUnit: 'day',
          cycleValue: 0,
        ),
        throwsArgumentError,
      );
    });

    test('非法周期单位抛出异常', () {
      expect(
        () => service.expiryDateFrom(
          openedDate: DateTime(2026, 11, 10),
          cycleUnit: 'hour',
          cycleValue: 5,
        ),
        throwsArgumentError,
      );
    });
  });

  group('过期判定（today >= expiryDate 即已过期）', () {
    test('到期当天即为已过期（到期当天不能仍计入使用中）', () {
      expect(service.isExpired(DateTime(2026, 11, 24)), isTrue);
    });

    test('到期前一天（明天到期）未过期', () {
      expect(service.isExpired(DateTime(2026, 11, 25)), isFalse);
    });

    test('今天之前（昨天已到期）已过期', () {
      expect(service.isExpired(DateTime(2026, 11, 23)), isTrue);
    });

    test('剩余天数：今天到期为 0', () {
      expect(service.daysRemaining(DateTime(2026, 11, 24)), 0);
    });

    test('「今天到期」不影响过期判定', () {
      expect(service.isExpiringToday(DateTime(2026, 11, 24)), isTrue);
      expect(service.isExpired(DateTime(2026, 11, 24)), isTrue);
    });
  });

  group('提前提醒日', () {
    test('expiryDate - advanceDays', () {
      final reminder = service.reminderDate(
        expiryDate: DateTime(2026, 11, 24),
        advanceDays: 3,
      );
      expect(reminder, DateTime(2026, 11, 21));
    });

    test('提前提醒当天进入窗口', () {
      // 今天是 2026-11-24，到期 11-27 提前 3 天 → 提醒日即今天。
      final reminder = service.reminderDate(
        expiryDate: DateTime(2026, 11, 27),
        advanceDays: 3,
      );
      expect(reminder, DateTime(2026, 11, 24));
      expect(service.isExpiringSoon(DateTime(2026, 11, 27), 3), isTrue);
    });

    test('负提前天数抛出异常', () {
      expect(
        () => service.reminderDate(
          expiryDate: DateTime(2026, 11, 24),
          advanceDays: -1,
        ),
        throwsArgumentError,
      );
    });

    test('dueState 三态映射', () {
      expect(service.dueState(DateTime(2026, 12, 1), 3), LensDueState.upcoming);
      expect(
        service.dueState(DateTime(2026, 11, 26), 3),
        LensDueState.expiringSoon,
      );
      expect(service.dueState(DateTime(2026, 11, 24), 3), LensDueState.expired);
    });
  });

  group('护理液到期日（取较早依据）', () {
    test('仅有包装有效期', () {
      final expiry = service.careSolutionExpiryDate(
        packageExpiryDate: DateTime(2026, 12, 31),
      );
      expect(expiry, DateTime(2026, 12, 31));
    });

    test('仅有开封日期 + 开封后有效天数', () {
      final expiry = service.careSolutionExpiryDate(
        openedAt: DateTime(2026, 11, 1),
        afterOpenValidDays: 30,
      );
      expect(expiry, DateTime(2026, 12, 1));
    });

    test('两者都有时取较早日期', () {
      final expiry = service.careSolutionExpiryDate(
        packageExpiryDate: DateTime(2026, 11, 20),
        openedAt: DateTime(2026, 11, 1),
        afterOpenValidDays: 30,
      );
      expect(expiry, DateTime(2026, 11, 20));
    });

    test('缺少依据时不编造日期', () {
      expect(service.careSolutionExpiryDate(), isNull);
      expect(
        service.careSolutionExpiryDate(openedAt: DateTime(2026, 11, 1)),
        isNull,
      );
    });
  });
}
