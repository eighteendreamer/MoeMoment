//! 护理液业务：更换提醒、更换历史、护理液信息与到期计算。
//!
//! 更换提醒与护理液到期提醒是两项独立业务，配置表、计算与通知互不影响。

use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, DatabaseConnection, EntityTrait, QueryFilter,
    QueryOrder, QuerySelect, Set, TransactionTrait,
};

use crate::db::entities::{
    care_bottle, care_change_log, care_change_reminder, care_expiry_setting,
};
use crate::domain::dates::{fmt_date, now_iso, parse_opt_date, today, normalize_time};
use crate::domain::lens::{care_solution_expiry, next_change_date};
use crate::dto::{
    CareBottleDto, CareBottleInput, CareChangeLogDto, CareChangeReminderDto, CareChangeReminderInput,
    CareExpiryReminderDto, CareExpiryReminderInput, CareStateDto,
};
use crate::error::{AppError, AppResult};
use crate::services::parse_required_date;

const REMINDER_ID: i32 = 1;
const MAX_HISTORY: u64 = 20;

fn bottle_to_dto(model: care_bottle::Model) -> CareBottleDto {
    let package_expiry = parse_opt_date(model.package_expiry_date.as_deref());
    let opened_at = parse_opt_date(model.opened_at.as_deref());
    let expiry = care_solution_expiry(package_expiry, opened_at, model.after_open_valid_days);
    let today = today();
    CareBottleDto {
        id: model.id,
        brand: model.brand,
        name: model.name,
        opened_at: model.opened_at,
        package_expiry_date: model.package_expiry_date,
        after_open_valid_days: model.after_open_valid_days,
        is_current: model.is_current,
        note: model.note,
        expiry_date: expiry.map(fmt_date),
        days_remaining: expiry.map(|date| (date - today).num_days()),
        expired: expiry.map(|date| today >= date).unwrap_or(false),
    }
}

pub async fn current_bottle(db: &DatabaseConnection) -> AppResult<Option<CareBottleDto>> {
    let rows = care_bottle::Entity::find()
        .filter(care_bottle::Column::IsCurrent.eq(true))
        .order_by_desc(care_bottle::Column::UpdatedAt)
        .all(db)
        .await?;

    Ok(rows.into_iter().next().map(bottle_to_dto))
}

pub async fn all_bottles(db: &DatabaseConnection) -> AppResult<Vec<CareBottleDto>> {
    let rows = care_bottle::Entity::find()
        .order_by_desc(care_bottle::Column::IsCurrent)
        .order_by_desc(care_bottle::Column::UpdatedAt)
        .all(db)
        .await?;
    Ok(rows.into_iter().map(bottle_to_dto).collect())
}

async fn change_reminder_model<C: ConnectionTrait>(db: &C) -> AppResult<care_change_reminder::Model> {
    care_change_reminder::Entity::find_by_id(REMINDER_ID)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("护理液更换提醒配置缺失，请重启应用以恢复默认配置"))
}

async fn expiry_setting_model<C: ConnectionTrait>(db: &C) -> AppResult<care_expiry_setting::Model> {
    care_expiry_setting::Entity::find_by_id(REMINDER_ID)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("护理液到期提醒配置缺失，请重启应用以恢复默认配置"))
}

async fn change_dto<C: ConnectionTrait>(db: &C, model: care_change_reminder::Model) -> AppResult<CareChangeReminderDto> {
    let logs = care_change_log::Entity::find()
        .filter(care_change_log::Column::ReminderId.eq(REMINDER_ID))
        .order_by_desc(care_change_log::Column::ChangedAt)
        .order_by_desc(care_change_log::Column::Id)
        .limit(MAX_HISTORY)
        .all(db)
        .await?
        .into_iter()
        .map(|row| CareChangeLogDto {
            id: row.id,
            changed_at: row.changed_at,
            note: row.note,
        })
        .collect();

    let today = today();
    let days_until_next = parse_opt_date(model.next_changed_date.as_deref())
        .map(|date| (date - today).num_days());

    Ok(CareChangeReminderDto {
        is_active: model.is_active,
        frequency: model.frequency,
        interval_days: model.interval_days,
        reminder_time: model.reminder_time,
        last_changed_date: model.last_changed_date,
        next_changed_date: model.next_changed_date,
        days_until_next,
        history: logs,
    })
}

fn expiry_dto(model: care_expiry_setting::Model) -> CareExpiryReminderDto {
    CareExpiryReminderDto {
        is_active: model.is_active,
        advance_days: model.advance_days,
        reminder_time: model.reminder_time,
    }
}

pub async fn get_state(db: &DatabaseConnection) -> AppResult<CareStateDto> {
    let change = change_dto(db, change_reminder_model(db).await?).await?;
    let expiry = expiry_dto(expiry_setting_model(db).await?);
    let bottle = current_bottle(db).await?;
    Ok(CareStateDto {
        change,
        expiry,
        bottle,
    })
}

pub async fn update_change_reminder(
    db: &DatabaseConnection,
    input: CareChangeReminderInput,
) -> AppResult<CareStateDto> {
    let time = normalize_time(&input.reminder_time)
        .ok_or_else(|| AppError::msg("提醒时间格式应为 HH:mm"))?;
    if input.interval_days <= 0 {
        return Err(AppError::msg("更换间隔必须是正整数天"));
    }
    if input.interval_days > 365 {
        return Err(AppError::msg("更换间隔过长，请检查"));
    }
    let frequency = input.frequency.trim().to_string();
    if frequency.is_empty() {
        return Err(AppError::msg("请选择更换频率"));
    }

    let existing = change_reminder_model(db).await?;
    let last = parse_opt_date(existing.last_changed_date.as_deref());
    // 间隔变化后，下次更换日期必须按新间隔重算，而不是沿用旧值
    let next = next_change_date(last, input.interval_days);

    let mut active: care_change_reminder::ActiveModel = existing.into();
    active.is_active = Set(input.is_active);
    active.frequency = Set(frequency);
    active.interval_days = Set(input.interval_days);
    active.reminder_time = Set(time);
    active.next_changed_date = Set(next.map(fmt_date));
    active.updated_at = Set(now_iso());
    active.update(db).await?;

    get_state(db).await
}

pub async fn update_expiry_reminder(
    db: &DatabaseConnection,
    input: CareExpiryReminderInput,
) -> AppResult<CareStateDto> {
    let time = normalize_time(&input.reminder_time)
        .ok_or_else(|| AppError::msg("提醒时间格式应为 HH:mm"))?;
    if !(0..=60).contains(&input.advance_days) {
        return Err(AppError::msg("提前天数应在 0 到 60 天之间"));
    }

    let existing = expiry_setting_model(db).await?;
    let mut active: care_expiry_setting::ActiveModel = existing.into();
    active.is_active = Set(input.is_active);
    active.advance_days = Set(input.advance_days);
    active.reminder_time = Set(time);
    active.updated_at = Set(now_iso());
    active.update(db).await?;

    get_state(db).await
}

/// 「已更换护理液」：写入历史、更新上次日期并按间隔计算下次日期，全部在一个事务内。
pub async fn mark_changed(
    db: &DatabaseConnection,
    changed_at: Option<String>,
    note: Option<String>,
) -> AppResult<CareStateDto> {
    let date = match parse_required_date(changed_at, "更换日期")? {
        Some(date) => date,
        None => today(),
    };
    if date > today() {
        return Err(AppError::msg("更换日期不能晚于今天"));
    }

    let txn = db.begin().await?;
    let existing = change_reminder_model(&txn).await?;
    let interval = existing.interval_days;

    care_change_log::ActiveModel {
        reminder_id: Set(REMINDER_ID),
        changed_at: Set(fmt_date(date)),
        note: Set(note.and_then(|raw| {
            let trimmed = raw.trim().to_string();
            if trimmed.is_empty() { None } else { Some(trimmed) }
        })),
        created_at: Set(now_iso()),
        ..Default::default()
    }
    .insert(&txn)
    .await?;

    let mut active: care_change_reminder::ActiveModel = existing.into();
    active.last_changed_date = Set(Some(fmt_date(date)));
    active.next_changed_date = Set(next_change_date(Some(date), interval).map(fmt_date));
    active.updated_at = Set(now_iso());
    active.update(&txn).await?;

    txn.commit().await?;
    get_state(db).await
}

/// 新增或更新护理液信息；切换为「当前使用」时，其它护理液自动取消当前标记。
pub async fn save_bottle(db: &DatabaseConnection, input: CareBottleInput) -> AppResult<CareStateDto> {
    if input.brand.trim().is_empty() && input.name.trim().is_empty() {
        return Err(AppError::msg("请至少填写护理液品牌或名称"));
    }
    let opened_at = parse_required_date(input.opened_at.clone(), "开封日期")?;
    let package_expiry = parse_required_date(input.package_expiry_date.clone(), "包装有效期")?;
    if let Some(days) = input.after_open_valid_days
        && days <= 0
    {
        return Err(AppError::msg("开封后有效天数必须是正整数"));
    }

    let txn = db.begin().await?;

    if input.is_current {
        care_bottle::Entity::update_many()
            .col_expr(care_bottle::Column::IsCurrent, sea_orm::sea_query::Expr::value(false))
            .filter(care_bottle::Column::IsCurrent.eq(true))
            .exec(&txn)
            .await?;
    }

    let now = now_iso();
    match input.id {
        Some(id) => {
            let existing = care_bottle::Entity::find_by_id(id)
                .one(&txn)
                .await?
                .ok_or_else(|| AppError::msg("护理液记录不存在"))?;
            let mut active: care_bottle::ActiveModel = existing.into();
            active.brand = Set(input.brand.trim().to_string());
            active.name = Set(input.name.trim().to_string());
            active.opened_at = Set(opened_at.map(fmt_date));
            active.package_expiry_date = Set(package_expiry.map(fmt_date));
            active.after_open_valid_days = Set(input.after_open_valid_days);
            active.is_current = Set(input.is_current);
            active.note = Set(input.note.and_then(|raw| {
                let trimmed = raw.trim().to_string();
                if trimmed.is_empty() { None } else { Some(trimmed) }
            }));
            active.updated_at = Set(now);
            active.update(&txn).await?;
        }
        None => {
            care_bottle::ActiveModel {
                brand: Set(input.brand.trim().to_string()),
                name: Set(input.name.trim().to_string()),
                opened_at: Set(opened_at.map(fmt_date)),
                package_expiry_date: Set(package_expiry.map(fmt_date)),
                after_open_valid_days: Set(input.after_open_valid_days),
                is_current: Set(input.is_current),
                note: Set(input.note.and_then(|raw| {
                    let trimmed = raw.trim().to_string();
                    if trimmed.is_empty() { None } else { Some(trimmed) }
                })),
                created_at: Set(now.clone()),
                updated_at: Set(now),
                ..Default::default()
            }
            .insert(&txn)
            .await?;
        }
    }

    txn.commit().await?;

    // 若关闭了所有当前标记，至少保留一条当前护理液，避免状态页为空
    let has_current = care_bottle::Entity::find()
        .filter(care_bottle::Column::IsCurrent.eq(true))
        .one(db)
        .await?;
    if has_current.is_none()
        && let Some(latest) = care_bottle::Entity::find()
            .order_by_desc(care_bottle::Column::UpdatedAt)
            .one(db)
            .await?
    {
        let mut active: care_bottle::ActiveModel = latest.into();
        active.is_current = Set(true);
        active.update(db).await?;
    }

    get_state(db).await
}
