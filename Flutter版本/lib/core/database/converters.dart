import 'package:drift/drift.dart';

/// 业务日期（本地日历日期）专用转换器。
///
/// 以 `yyyy-MM-dd` 文本存储，避免 Drift 默认的 UTC 时间戳在不同时区下产生日期偏移。
/// 时间戳字段（createdAt / updatedAt 等）不使用该转换器。
class DateIsoConverter extends TypeConverter<DateTime, String> {
  const DateIsoConverter();

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// 将日期时间归一化为本地日历日期（去掉时间部分）。
  static DateTime toLocalDate(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String encode(DateTime value) => _formatDate(value);

  static DateTime? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  @override
  DateTime fromSql(String fromDb) => tryParse(fromDb) ?? DateTime(1970, 1, 1);

  @override
  String toSql(DateTime value) => _formatDate(value);
}

/// 时间字段（`HH:mm`）转换器，用于提醒时间。
class TimeOfDayText {
  const TimeOfDayText(this.hour, this.minute);

  factory TimeOfDayText.parse(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return TimeOfDayText(hour.clamp(0, 23), minute.clamp(0, 59));
  }

  final int hour;
  final int minute;

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
