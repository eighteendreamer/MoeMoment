//! 日期与周期计算的唯一可信实现。
//!
//! 所有业务日期都是「本地日历日期」，不做 UTC 转换；月、年按自然日历推进，
//! 月末与闰年没有对应日期时截断到目标月份最后一天（chrono 的 Months 语义）。

use chrono::{Datelike, Days, Local, Months, NaiveDate};

/// 当前本地日期。业务代码不应各自调用系统时间，统一走这里。
pub fn today() -> NaiveDate {
    Local::now().date_naive()
}

/// 当前本地时间戳（RFC3339），用于 created_at / updated_at。
pub fn now_iso() -> String {
    Local::now().to_rfc3339_opts(chrono::SecondsFormat::Secs, true)
}

/// 业务日期序列化为 `YYYY-MM-DD`。
pub fn fmt_date(date: NaiveDate) -> String {
    date.format("%Y-%m-%d").to_string()
}

/// 解析业务日期，非法格式返回 None（不 panic、不猜测）。
pub fn parse_date(value: &str) -> Option<NaiveDate> {
    NaiveDate::parse_from_str(value.trim(), "%Y-%m-%d").ok()
}

pub fn parse_opt_date(value: Option<&str>) -> Option<NaiveDate> {
    value.and_then(|raw| {
        let trimmed = raw.trim();
        if trimmed.is_empty() {
            None
        } else {
            parse_date(trimmed)
        }
    })
}

/// 校验 `HH:mm` 形式的提醒时间，返回规范化字符串。
pub fn normalize_time(value: &str) -> Option<String> {
    let (hour, minute) = value.trim().split_once(':')?;
    let hour: u32 = hour.parse().ok()?;
    let minute: u32 = minute.parse().ok()?;
    if hour > 23 || minute > 59 {
        return None;
    }
    Some(format!("{hour:02}:{minute:02}"))
}

/// 周期单位。只支持 day / week / month / year，自定义周期由数值表达。
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum CycleUnit {
    Day,
    Week,
    Month,
    Year,
}

impl CycleUnit {
    pub fn parse(value: &str) -> Option<Self> {
        match value.trim().to_ascii_lowercase().as_str() {
            "day" => Some(Self::Day),
            "week" => Some(Self::Week),
            "month" => Some(Self::Month),
            "year" => Some(Self::Year),
            _ => None,
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Day => "day",
            Self::Week => "week",
            Self::Month => "month",
            Self::Year => "year",
        }
    }
}

/// 从起始日期推进一个周期，得到到期日。
///
/// - 日、周按自然日推进；
/// - 月、年按自然月推进，日期越界时截断（1 月 31 日 + 1 月 = 2 月最后一天）。
pub fn add_cycle(start: NaiveDate, unit: CycleUnit, value: i32) -> Option<NaiveDate> {
    if value <= 0 {
        return None;
    }
    match unit {
        CycleUnit::Day => start.checked_add_days(Days::new(value as u64)),
        CycleUnit::Week => start.checked_add_days(Days::new(value as u64 * 7)),
        CycleUnit::Month => start.checked_add_months(Months::new(value as u32)),
        CycleUnit::Year => start.checked_add_months(Months::new((value as u32).checked_mul(12)?)),
    }
}

/// 毫秒精度无关的「相隔天数」：expiry - today。
pub fn days_between(today: NaiveDate, target: NaiveDate) -> i64 {
    (target - today).num_days()
}

/// 提前提醒日 = 到期日 - advance_days。
pub fn advance_date(expiry: NaiveDate, advance_days: i32) -> NaiveDate {
    expiry - chrono::Duration::days(advance_days.max(0) as i64)
}

/// 今天的日期序号（用于去重键）。
pub fn compact_date(date: NaiveDate) -> String {
    format!("{:04}{:02}{:02}", date.year(), date.month(), date.day())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn d(s: &str) -> NaiveDate {
        parse_date(s).expect("测试日期必须合法")
    }

    #[test]
    fn day_and_week_cycles_follow_calendar_days() {
        assert_eq!(
            add_cycle(d("2026-03-01"), CycleUnit::Day, 1),
            Some(d("2026-03-02"))
        );
        assert_eq!(
            add_cycle(d("2026-03-01"), CycleUnit::Week, 2),
            Some(d("2026-03-15"))
        );
    }

    #[test]
    fn month_cycles_use_natural_months() {
        assert_eq!(
            add_cycle(d("2026-03-15"), CycleUnit::Month, 1),
            Some(d("2026-04-15"))
        );
        assert_eq!(
            add_cycle(d("2026-01-15"), CycleUnit::Month, 3),
            Some(d("2026-04-15"))
        );
        assert_eq!(
            add_cycle(d("2026-01-15"), CycleUnit::Month, 6),
            Some(d("2026-07-15"))
        );
    }

    #[test]
    fn month_end_is_clamped_to_last_day() {
        // 1 月 31 日 + 1 月 = 2 月最后一天
        assert_eq!(
            add_cycle(d("2026-01-31"), CycleUnit::Month, 1),
            Some(d("2026-02-28"))
        );
        // 闰年 1 月 31 日 + 1 月 = 2 月 29 日
        assert_eq!(
            add_cycle(d("2028-01-31"), CycleUnit::Month, 1),
            Some(d("2028-02-29"))
        );
        // 8 月 31 日 + 1 月 = 9 月 30 日
        assert_eq!(
            add_cycle(d("2026-08-31"), CycleUnit::Month, 1),
            Some(d("2026-09-30"))
        );
    }

    #[test]
    fn year_cycles_follow_calendar_years() {
        assert_eq!(
            add_cycle(d("2026-05-20"), CycleUnit::Year, 1),
            Some(d("2027-05-20"))
        );
        // 闰年 2 月 29 日 + 1 年 = 次年 2 月最后一天
        assert_eq!(
            add_cycle(d("2028-02-29"), CycleUnit::Year, 1),
            Some(d("2029-02-28"))
        );
        // 18 个月的自定义周期
        assert_eq!(
            add_cycle(d("2026-01-10"), CycleUnit::Month, 18),
            Some(d("2027-07-10"))
        );
    }

    #[test]
    fn invalid_cycle_value_returns_none() {
        assert_eq!(add_cycle(d("2026-01-01"), CycleUnit::Day, 0), None);
        assert_eq!(add_cycle(d("2026-01-01"), CycleUnit::Month, -1), None);
    }

    #[test]
    fn advance_date_moves_backwards() {
        assert_eq!(advance_date(d("2026-03-10"), 3), d("2026-03-07"));
        assert_eq!(advance_date(d("2026-03-10"), 0), d("2026-03-10"));
    }

    #[test]
    fn time_normalization_rejects_out_of_range() {
        assert_eq!(normalize_time("9:05").as_deref(), Some("09:05"));
        assert_eq!(normalize_time("23:59").as_deref(), Some("23:59"));
        assert_eq!(normalize_time("24:00"), None);
        assert_eq!(normalize_time("09:60"), None);
        assert_eq!(normalize_time("morning"), None);
    }

    #[test]
    fn date_format_roundtrip() {
        let date = d("2026-11-25");
        assert_eq!(fmt_date(date), "2026-11-25");
        assert_eq!(parse_opt_date(Some("")), None);
        assert_eq!(parse_opt_date(Some("2026-11-25")), Some(date));
        assert_eq!(parse_opt_date(None), None);
    }
}
