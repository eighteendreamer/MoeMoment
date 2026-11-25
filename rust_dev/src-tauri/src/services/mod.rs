//! 业务服务层：数据库读写、事务与规则编排。命令层只做参数转换与调用。

pub mod care;
pub mod cycle;
pub mod lens;
pub mod media;
pub mod notification;
pub mod reminder_mobile;
pub mod settings;
pub mod updater;
pub mod windows_toast;

use chrono::NaiveDate;

use crate::error::{AppError, AppResult};

/// 把可选日期字符串解析为日期；格式非法时明确报错，不静默丢弃。
pub fn parse_required_date(value: Option<String>, field: &str) -> AppResult<Option<NaiveDate>> {
    match value {
        None => Ok(None),
        Some(raw) if raw.trim().is_empty() => Ok(None),
        Some(raw) => crate::domain::dates::parse_date(&raw)
            .map(Some)
            .ok_or_else(|| AppError::msg(format!("{field}不是合法日期（应为 YYYY-MM-DD）"))),
    }
}
