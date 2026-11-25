//! 美瞳到期与状态的业务规则（纯函数，可测试，不依赖数据库）。
//!
//! 核心约定：
//! - 持久化状态只有 unopened / opened / discarded；
//! - expired 由日期动态推导，不写库；
//! - 到期日当天即视为已过期（`today >= expiry_date`）；
//! - 已开封时「周期到期日」和「包装有效期」都存在则取较早者。

use chrono::NaiveDate;

use crate::domain::dates::{add_cycle, advance_date, days_between, CycleUnit};

pub const STATUS_UNOPENED: &str = "unopened";
pub const STATUS_OPENED: &str = "opened";
pub const STATUS_DISCARDED: &str = "discarded";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum LensState {
    Unopened,
    InUse,
    Expired,
    Discarded,
}

impl LensState {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Unopened => "unopened",
            Self::InUse => "in_use",
            Self::Expired => "expired",
            Self::Discarded => "discarded",
        }
    }
}

/// 到期日的来源，便于 UI 解释「为什么这天到期」。
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ExpirySource {
    /// 无任何可用日期
    None,
    /// 仅包装有效期
    Package,
    /// 仅使用周期
    Usage,
    /// 两者都有，取较早者
    EarlierOfBoth,
}

impl ExpirySource {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::None => "none",
            Self::Package => "package",
            Self::Usage => "usage",
            Self::EarlierOfBoth => "earlier_of_both",
        }
    }
}

#[derive(Clone, Debug)]
pub struct ExpiryInfo {
    pub expiry_date: Option<NaiveDate>,
    pub days_remaining: Option<i64>,
    #[allow(dead_code)] // 由 derive_state 复用前先暴露出来，测试中会直接断言
    pub expired: bool,
    pub source: ExpirySource,
}

impl ExpiryInfo {
    pub fn none() -> Self {
        Self {
            expiry_date: None,
            days_remaining: None,
            expired: false,
            source: ExpirySource::None,
        }
    }
}

/// 计算单副美瞳的到期信息。
///
/// - `discarded`：不产生到期日，也不参与提醒；
/// - `opened` + 开封日：周期到期日 = 开封日 + 周期；与包装有效期取较早；
/// - `unopened`：只用包装有效期，未填写则不推断。
pub fn compute_expiry(
    status: &str,
    opened_at: Option<NaiveDate>,
    cycle: Option<(CycleUnit, i32)>,
    package_expiry: Option<NaiveDate>,
    today: NaiveDate,
) -> ExpiryInfo {
    if status == STATUS_DISCARDED {
        return ExpiryInfo::none();
    }

    let usage_expiry = if status == STATUS_OPENED {
        match (opened_at, cycle) {
            (Some(opened), Some((unit, value))) => add_cycle(opened, unit, value),
            _ => None,
        }
    } else {
        None
    };

    let (expiry, source) = match (usage_expiry, package_expiry) {
        (Some(usage), Some(package)) => {
            if usage <= package {
                (Some(usage), ExpirySource::EarlierOfBoth)
            } else {
                (Some(package), ExpirySource::EarlierOfBoth)
            }
        }
        (Some(usage), None) => (Some(usage), ExpirySource::Usage),
        (None, Some(package)) => (Some(package), ExpirySource::Package),
        (None, None) => (None, ExpirySource::None),
    };

    match expiry {
        Some(date) => ExpiryInfo {
            expiry_date: Some(date),
            days_remaining: Some(days_between(today, date)),
            expired: today >= date,
            source,
        },
        None => ExpiryInfo::none(),
    }
}

/// 由持久化状态 + 到期信息推导展示状态。
pub fn derive_state(status: &str, expiry: Option<NaiveDate>, today: NaiveDate) -> LensState {
    if status == STATUS_DISCARDED {
        return LensState::Discarded;
    }
    let expired = expiry.map(|date| today >= date).unwrap_or(false);
    match (status, expired) {
        (STATUS_OPENED, true) => LensState::Expired,
        (STATUS_OPENED, false) => LensState::InUse,
        (_, true) => LensState::Expired,
        (_, false) => LensState::Unopened,
    }
}

/// 是否进入「即将到期」区间：今天已到达提前提醒日，但还没过期。
pub fn is_expiring_soon(
    expiry: Option<NaiveDate>,
    today: NaiveDate,
    advance_days: i32,
) -> bool {
    match expiry {
        Some(date) => {
            let remind_from = advance_date(date, advance_days);
            today >= remind_from && today < date
        }
        None => false,
    }
}

/// 护理液到期日：包装有效期与「开封日 + 开封后有效天数」取较早者；都缺失则不编造。
pub fn care_solution_expiry(
    package_expiry: Option<NaiveDate>,
    opened_at: Option<NaiveDate>,
    after_open_valid_days: Option<i32>,
) -> Option<NaiveDate> {
    let opened_expiry = match (opened_at, after_open_valid_days) {
        (Some(opened), Some(days)) if days > 0 => {
            opened.checked_add_days(chrono::Days::new(days as u64))
        }
        _ => None,
    };
    match (package_expiry, opened_expiry) {
        (Some(a), Some(b)) => Some(a.min(b)),
        (Some(a), None) => Some(a),
        (None, Some(b)) => Some(b),
        (None, None) => None,
    }
}

/// 下一次更换护理液的日期。
pub fn next_change_date(last_changed: Option<NaiveDate>, interval_days: i32) -> Option<NaiveDate> {
    let last = last_changed?;
    if interval_days <= 0 {
        return None;
    }
    last.checked_add_days(chrono::Days::new(interval_days as u64))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::dates::parse_date;

    fn d(s: &str) -> NaiveDate {
        parse_date(s).unwrap()
    }

    fn cycle(unit: CycleUnit, value: i32) -> Option<(CycleUnit, i32)> {
        Some((unit, value))
    }

    #[test]
    fn daily_lens_expires_next_day() {
        let info = compute_expiry(
            STATUS_OPENED,
            Some(d("2026-03-01")),
            cycle(CycleUnit::Day, 1),
            None,
            d("2026-03-01"),
        );
        assert_eq!(info.expiry_date, Some(d("2026-03-02")));
        assert_eq!(info.days_remaining, Some(1));
        assert!(!info.expired);
    }

    #[test]
    fn biweekly_monthly_quarterly_half_year_and_yearly() {
        let cases = [
            (CycleUnit::Week, 2, "2026-03-01", "2026-03-15"),
            (CycleUnit::Month, 1, "2026-03-01", "2026-04-01"),
            (CycleUnit::Month, 3, "2026-03-01", "2026-06-01"),
            (CycleUnit::Month, 6, "2026-03-01", "2026-09-01"),
            (CycleUnit::Year, 1, "2026-03-01", "2027-03-01"),
        ];
        for (unit, value, opened, expected) in cases {
            let info = compute_expiry(
                STATUS_OPENED,
                Some(d(opened)),
                cycle(unit, value),
                None,
                d(opened),
            );
            assert_eq!(info.expiry_date, Some(d(expected)), "{unit:?} {value}");
        }
    }

    #[test]
    fn expiry_day_counts_as_expired() {
        let opened = d("2026-03-01");
        let info = compute_expiry(
            STATUS_OPENED,
            Some(opened),
            cycle(CycleUnit::Month, 1),
            None,
            d("2026-04-01"),
        );
        assert!(info.expired);
        assert_eq!(info.days_remaining, Some(0));
        assert_eq!(
            derive_state(STATUS_OPENED, info.expiry_date, d("2026-04-01")),
            LensState::Expired
        );
    }

    #[test]
    fn advance_reminder_day_is_expiring_not_expired() {
        let expiry = d("2026-04-01");
        assert!(is_expiring_soon(Some(expiry), d("2026-03-29"), 3));
        assert!(!is_expiring_soon(Some(expiry), d("2026-03-28"), 3));
        assert!(!is_expiring_soon(Some(expiry), d("2026-04-01"), 3));
    }

    #[test]
    fn earlier_package_expiry_wins() {
        let info = compute_expiry(
            STATUS_OPENED,
            Some(d("2026-03-01")),
            cycle(CycleUnit::Month, 6),
            Some(d("2026-04-10")),
            d("2026-03-01"),
        );
        assert_eq!(info.expiry_date, Some(d("2026-04-10")));
        assert_eq!(info.source, ExpirySource::EarlierOfBoth);
    }

    #[test]
    fn usage_expiry_wins_when_earlier_than_package() {
        let info = compute_expiry(
            STATUS_OPENED,
            Some(d("2026-03-01")),
            cycle(CycleUnit::Day, 1),
            Some(d("2027-01-01")),
            d("2026-03-01"),
        );
        assert_eq!(info.expiry_date, Some(d("2026-03-02")));
        assert_eq!(info.source, ExpirySource::EarlierOfBoth);
    }

    #[test]
    fn unopened_without_package_date_has_no_expiry() {
        let info = compute_expiry(STATUS_UNOPENED, None, cycle(CycleUnit::Month, 1), None, d("2026-03-01"));
        assert_eq!(info.expiry_date, None);
        assert!(!info.expired);
        assert_eq!(
            derive_state(STATUS_UNOPENED, None, d("2026-03-01")),
            LensState::Unopened
        );
    }

    #[test]
    fn unopened_with_past_package_date_is_expired() {
        let info = compute_expiry(
            STATUS_UNOPENED,
            None,
            cycle(CycleUnit::Month, 1),
            Some(d("2026-02-01")),
            d("2026-03-01"),
        );
        assert!(info.expired);
        assert_eq!(
            derive_state(STATUS_UNOPENED, info.expiry_date, d("2026-03-01")),
            LensState::Expired
        );
    }

    #[test]
    fn discarded_lens_has_no_expiry_and_no_state() {
        let info = compute_expiry(
            STATUS_DISCARDED,
            Some(d("2026-03-01")),
            cycle(CycleUnit::Month, 1),
            Some(d("2026-03-20")),
            d("2026-03-05"),
        );
        assert!(!info.expired);
        assert_eq!(info.expiry_date, None);
        assert_eq!(
            derive_state(STATUS_DISCARDED, None, d("2026-03-05")),
            LensState::Discarded
        );
    }

    #[test]
    fn opened_without_open_date_only_uses_package() {
        let info = compute_expiry(
            STATUS_OPENED,
            None,
            cycle(CycleUnit::Month, 1),
            Some(d("2026-06-01")),
            d("2026-03-01"),
        );
        assert_eq!(info.expiry_date, Some(d("2026-06-01")));
        assert_eq!(info.source, ExpirySource::Package);
    }

    #[test]
    fn care_solution_takes_earlier_of_package_and_after_open() {
        assert_eq!(
            care_solution_expiry(Some(d("2026-12-31")), Some(d("2026-03-01")), Some(30)),
            Some(d("2026-03-31"))
        );
        assert_eq!(
            care_solution_expiry(Some(d("2026-03-10")), Some(d("2026-03-01")), Some(30)),
            Some(d("2026-03-10"))
        );
        assert_eq!(
            care_solution_expiry(None, Some(d("2026-03-01")), Some(90)),
            Some(d("2026-05-30"))
        );
        assert_eq!(care_solution_expiry(None, Some(d("2026-03-01")), None), None);
    }

    #[test]
    fn next_change_date_follows_interval() {
        assert_eq!(next_change_date(Some(d("2026-03-01")), 3), Some(d("2026-03-04")));
        assert_eq!(next_change_date(Some(d("2026-03-01")), 7), Some(d("2026-03-08")));
        assert_eq!(next_change_date(None, 3), None);
        assert_eq!(next_change_date(Some(d("2026-03-01")), 0), None);
    }
}
