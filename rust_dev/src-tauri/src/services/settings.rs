//! 应用设置：Key-Value 读写、三类提醒配置的入口。

use sea_orm::{ActiveModelTrait, DatabaseConnection, EntityTrait, Set};

use crate::db::entities::{app_setting, lens_expiry_setting};
use crate::domain::dates::{normalize_time, now_iso};
use crate::dto::{AppSettingsDto, LensReminderSettingDto, LensReminderSettingInput};
use crate::error::{AppError, AppResult};

pub const KEY_SYSTEM_NOTIFICATIONS: &str = "system_notifications_enabled";
pub const KEY_AUTO_UPDATE: &str = "auto_update_enabled";
pub const KEY_MIRROR_MODE: &str = "github_mirror_mode";
pub const KEY_UPDATE_CHANNEL: &str = "update_channel";
pub const KEY_LAST_CHECK: &str = "last_update_check_at";

const ALLOWED_KEYS: [&str; 6] = [
    KEY_SYSTEM_NOTIFICATIONS,
    KEY_AUTO_UPDATE,
    KEY_MIRROR_MODE,
    KEY_UPDATE_CHANNEL,
    KEY_LAST_CHECK,
    "notification_permission_prompted",
];

pub async fn get_raw(db: &DatabaseConnection, key: &str) -> AppResult<Option<String>> {
    Ok(app_setting::Entity::find_by_id(key.to_string())
        .one(db)
        .await?
        .map(|row| row.value))
}

pub async fn set_raw(db: &DatabaseConnection, key: &str, value: &str) -> AppResult<()> {
    let existing = app_setting::Entity::find_by_id(key.to_string()).one(db).await?;
    match existing {
        Some(model) => {
            let mut active: app_setting::ActiveModel = model.into();
            active.value = Set(value.to_string());
            active.updated_at = Set(now_iso());
            active.update(db).await?;
        }
        None => {
            app_setting::ActiveModel {
                key: Set(key.to_string()),
                value: Set(value.to_string()),
                updated_at: Set(now_iso()),
            }
            .insert(db)
            .await?;
        }
    }
    Ok(())
}

async fn get_bool(db: &DatabaseConnection, key: &str, fallback: bool) -> bool {
    get_raw(db, key)
        .await
        .ok()
        .flatten()
        .map(|value| value == "true")
        .unwrap_or(fallback)
}

pub async fn get_app_settings(db: &DatabaseConnection) -> AppResult<AppSettingsDto> {
    let mirror = get_raw(db, KEY_MIRROR_MODE)
        .await?
        .unwrap_or_else(|| "auto".to_string());
    let channel = get_raw(db, KEY_UPDATE_CHANNEL)
        .await?
        .unwrap_or_else(|| "stable".to_string());
    let last_check = get_raw(db, KEY_LAST_CHECK).await?;

    Ok(AppSettingsDto {
        system_notifications_enabled: get_bool(db, KEY_SYSTEM_NOTIFICATIONS, true).await,
        auto_update_enabled: get_bool(db, KEY_AUTO_UPDATE, true).await,
        github_mirror_mode: mirror,
        update_channel: channel,
        last_update_check_at: last_check.filter(|value| !value.trim().is_empty()),
    })
}

/// 写入单个设置项，只允许白名单内的键，值做基本校验。
pub async fn set_setting(db: &DatabaseConnection, key: &str, value: &str) -> AppResult<AppSettingsDto> {
    if !ALLOWED_KEYS.contains(&key) {
        return Err(AppError::msg(format!("不支持的设置项：{key}")));
    }

    let normalized = match key {
        KEY_SYSTEM_NOTIFICATIONS | KEY_AUTO_UPDATE => {
            if value != "true" && value != "false" {
                return Err(AppError::msg("开关值只能是 true 或 false"));
            }
            value.to_string()
        }
        KEY_MIRROR_MODE => {
            if !["official", "mirror", "auto"].contains(&value) {
                return Err(AppError::msg("镜像模式只能是 official / mirror / auto"));
            }
            value.to_string()
        }
        KEY_UPDATE_CHANNEL => {
            if !["stable", "beta"].contains(&value) {
                return Err(AppError::msg("更新渠道只能是 stable / beta"));
            }
            value.to_string()
        }
        _ => value.to_string(),
    };

    set_raw(db, key, &normalized).await?;
    get_app_settings(db).await
}

pub async fn lens_reminder(db: &DatabaseConnection) -> AppResult<LensReminderSettingDto> {
    let model = lens_expiry_setting::Entity::find_by_id(1).one(db).await?;
    match model {
        Some(row) => Ok(LensReminderSettingDto {
            is_active: row.is_active,
            advance_days: row.advance_days,
            reminder_time: row.reminder_time,
        }),
        None => Ok(LensReminderSettingDto {
            is_active: true,
            advance_days: crate::services::lens::DEFAULT_ADVANCE_DAYS,
            reminder_time: "09:00".to_string(),
        }),
    }
}

pub async fn update_lens_reminder(
    db: &DatabaseConnection,
    input: LensReminderSettingInput,
) -> AppResult<LensReminderSettingDto> {
    let time = normalize_time(&input.reminder_time)
        .ok_or_else(|| AppError::msg("提醒时间格式应为 HH:mm"))?;
    if !(0..=60).contains(&input.advance_days) {
        return Err(AppError::msg("提前天数应在 0 到 60 天之间"));
    }

    let existing = lens_expiry_setting::Entity::find_by_id(1)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("提醒配置缺失，请重启应用以恢复默认配置"))?;

    let mut active: lens_expiry_setting::ActiveModel = existing.into();
    active.is_active = Set(input.is_active);
    active.advance_days = Set(input.advance_days);
    active.reminder_time = Set(time);
    active.updated_at = Set(now_iso());
    active.update(db).await?;

    lens_reminder(db).await
}
