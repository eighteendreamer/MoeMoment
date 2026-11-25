//! 本地通知：权限、计划生成、去重与发送。
//!
//! 说明（如实告知平台能力）：
//! - 通知权限与应用内总开关是两件事，权限必须从系统读取；
//! - 调度采用「计划表 + 前台轮询」：应用启动、回到前台以及运行期间每分钟检查一次；
//! - Android / iOS 上应用被系统完全杀死后无法保证准点触发，需要原生后台调度插件；
//!   这里不伪装成系统级定时通知。

use chrono::{Local, NaiveDate, TimeZone, Timelike};
use sea_orm::{
    ColumnTrait, ConnectionTrait, DatabaseBackend, DatabaseConnection, EntityTrait, QueryFilter,
    QueryOrder, QuerySelect, Statement,
};
use tauri::{AppHandle, Manager};
use tauri_plugin_notification::{NotificationExt, PermissionState};

use crate::db::entities::{care_bottle, notification_log};
use crate::domain::dates::{advance_date, compact_date, fmt_date, now_iso, parse_opt_date, today};
use crate::domain::lens::care_solution_expiry;
use crate::dto::{NotificationLogDto, NotificationPermissionDto};
use crate::error::AppResult;
use crate::services::{care, lens, reminder_mobile, settings};

/// Android 上已经交给系统闹钟的通知日志 id（避免前台轮询重复发送）
#[cfg(target_os = "android")]
static NATIVE_SCHEDULED: std::sync::Mutex<Option<std::collections::HashSet<i32>>> =
    std::sync::Mutex::new(None);

const TARGET_LENS: &str = "lens_expiry";
const TARGET_CARE_CHANGE: &str = "care_change";
const TARGET_CARE_EXPIRY: &str = "care_expiry";

pub fn permission_state(app: &AppHandle) -> NotificationPermissionDto {
    let state = app.notification().permission_state();
    let granted = matches!(state, Ok(PermissionState::Granted));
    let can_request = matches!(state, Ok(PermissionState::Prompt) | Ok(PermissionState::PromptWithRationale) | Err(_));

    let platform_note = if cfg!(target_os = "android") {
        "Android：提醒由系统闹钟调度，关闭应用后仍会触发。".to_string()
    } else if cfg!(target_os = "ios") {
        "iOS：仅应用运行时提醒。".to_string()
    } else {
        "桌面端：关闭应用后提醒不会触发。".to_string()
    };

    NotificationPermissionDto {
        granted,
        can_request,
        platform_note,
    }
}

pub fn request_permission(app: &AppHandle) -> NotificationPermissionDto {
    let _ = app.notification().request_permission();
    permission_state(app)
}

/// 重新生成计划：先清掉未发送的计划，再按当前数据重建（已发送记录保留用于去重）。
pub async fn reload_plans(app: &AppHandle, db: &DatabaseConnection) -> AppResult<()> {
    let settings_dto = settings::get_app_settings(db).await?;
    let master_on = settings_dto.system_notifications_enabled;

    db.execute_unprepared("DELETE FROM notification_logs WHERE status = 'scheduled'")
        .await?;

    if !master_on {
        log::info!("应用内通知总开关关闭，跳过计划生成");
        return Ok(());
    }

    let today = today();
    let lens_setting = settings::lens_reminder(db).await?;

    if lens_setting.is_active {
        plan_lens_reminders(db, lens_setting.advance_days, today).await?;
    }

    let care_state = care::get_state(db).await?;

    if care_state.change.is_active {
        plan_care_change(db, &care_state, today).await?;
    }

    if care_state.expiry.is_active {
        plan_care_expiry(db, care_state.expiry.advance_days, today).await?;
    }

    // Android：把未来的提醒交给系统闹钟，应用被关闭后也能触发
    if reminder_mobile::is_supported()
        && let Err(err) = sync_native_schedule(db).await
    {
        log::warn!("同步系统闹钟失败：{err}");
    }

    // 触发一次立即检查，让「今天该提醒」的条目尽快发出
    tick(app, db).await?;
    Ok(())
}

async fn insert_plan(
    db: &DatabaseConnection,
    key: &str,
    target_type: &str,
    target_id: Option<i32>,
    scheduled_date: &str,
    title: &str,
    body: &str,
) -> AppResult<()> {
    let sql = "INSERT OR IGNORE INTO notification_logs \
               (notification_key, target_type, target_id, scheduled_date, status, title, body) \
               VALUES (?, ?, ?, ?, 'scheduled', ?, ?)";
    db.execute_raw(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        sql,
        vec![
            key.into(),
            target_type.into(),
            target_id.into(),
            scheduled_date.into(),
            title.into(),
            body.into(),
        ],
    ))
    .await?;
    Ok(())
}

async fn plan_lens_reminders(db: &DatabaseConnection, advance_days: i32, today: chrono::NaiveDate) -> AppResult<()> {
    let items = lens::all_active(db, advance_days).await?;
    for item in items {
        let Some(expiry_raw) = item.expiry_date.clone() else {
            continue;
        };
        let Some(expiry) = parse_opt_date(Some(&expiry_raw)) else {
            continue;
        };
        if today >= expiry {
            // 已过期不再生成「即将到期」提醒，避免打扰
            continue;
        }
        let remind_on = advance_date(expiry, advance_days);
        let scheduled = if remind_on < today { today } else { remind_on };
        let days_left = (expiry - scheduled).num_days();

        let key = format!("{}:{}:{}", TARGET_LENS, item.id, compact_date(scheduled));
        let body = if days_left <= 0 {
            format!("{} {} 今天到期，建议及时更换。", item.brand, item.name)
        } else {
            format!(
                "{} {} 将于 {} 天后到期（{}）。",
                item.brand,
                item.name,
                days_left,
                expiry_raw
            )
        };
        insert_plan(
            db,
            &key,
            TARGET_LENS,
            Some(item.id),
            &fmt_date(scheduled),
            "美瞳即将到期",
            &body,
        )
        .await?;
    }
    Ok(())
}

async fn plan_care_change(
    db: &DatabaseConnection,
    state: &crate::dto::CareStateDto,
    today: chrono::NaiveDate,
) -> AppResult<()> {
    let Some(next_raw) = state.change.next_changed_date.clone() else {
        return Ok(());
    };
    let Some(next) = parse_opt_date(Some(&next_raw)) else {
        return Ok(());
    };
    let scheduled = if next < today { today } else { next };
    let overdue = next < today;

    let key = format!("{}:1:{}", TARGET_CARE_CHANGE, compact_date(scheduled));
    let body = if overdue {
        "已经超过计划更换护理液的日期，请尽快更换。".to_string()
    } else {
        "今天是计划更换护理液的日期。".to_string()
    };

    insert_plan(
        db,
        &key,
        TARGET_CARE_CHANGE,
        Some(1),
        &fmt_date(scheduled),
        "请更换护理液",
        &body,
    )
    .await
}

async fn plan_care_expiry(db: &DatabaseConnection, advance_days: i32, today: chrono::NaiveDate) -> AppResult<()> {
    let bottles = care_bottle::Entity::find().all(db).await?;
    for bottle in bottles {
        let package_expiry = parse_opt_date(bottle.package_expiry_date.as_deref());
        let opened_at = parse_opt_date(bottle.opened_at.as_deref());
        let Some(expiry) = care_solution_expiry(package_expiry, opened_at, bottle.after_open_valid_days) else {
            continue;
        };
        if today >= expiry {
            continue;
        }
        let remind_on = advance_date(expiry, advance_days);
        let scheduled = if remind_on < today { today } else { remind_on };
        let key = format!("{}:{}:{}", TARGET_CARE_EXPIRY, bottle.id, compact_date(scheduled));
        let body = format!(
            "{} {} 将于 {} 到期，请及时检查或更换。",
            bottle.brand,
            bottle.name,
            fmt_date(expiry)
        );
        insert_plan(
            db,
            &key,
            TARGET_CARE_EXPIRY,
            Some(bottle.id),
            &fmt_date(scheduled),
            "护理液即将到期",
            &body,
        )
        .await?;
    }
    Ok(())
}

/// 实际投递一条通知：Windows 用本应用 AUMID 的 Toast，其它平台用 Tauri 通知插件。
fn deliver(app: &AppHandle, title: &str, body: &str) -> Result<(), String> {
    #[cfg(target_os = "windows")]
    {
        let _ = app;
        return crate::services::windows_toast::show(title, body);
    }

    #[cfg(target_os = "android")]
    {
        let _ = app;
        return reminder_mobile::notify(0, title, body);
    }

    #[cfg(all(not(target_os = "windows"), not(target_os = "android")))]
    {
        app.notification()
            .builder()
            .title(title)
            .body(body)
            .show()
            .map_err(|err| err.to_string())
    }
}

/// 检查到点的计划并发送。返回本次实际发送的条数。
pub async fn tick(app: &AppHandle, db: &DatabaseConnection) -> AppResult<usize> {
    let settings_dto = settings::get_app_settings(db).await?;
    if !settings_dto.system_notifications_enabled {
        return Ok(0);
    }

    let now = chrono::Local::now();
    let today_str = fmt_date(now.date_naive());
    let now_hm = format!("{:02}:{:02}", now.hour(), now.minute());
    let permission = permission_state(app);

    let rows = notification_log_row(db, &today_str).await?;
    let mut sent = 0usize;

    for row in rows {
        if native_scheduled_contains(row.id) {
            // 已经排进系统闹钟，由 BroadcastReceiver 负责发送，避免重复通知
            continue;
        }
        let due_time = due_time_for(&row.target_type, db).await;
        if now_hm < due_time {
            continue;
        }

        if !permission.granted {
            // 权限未授予：保持计划状态，等待用户授权后补发
            continue;
        }

        let result = deliver(app, &row.title, &row.body);

        match result {
            Ok(()) => {
                mark_status(db, row.id, "sent", Some(&now_iso())).await?;
                sent += 1;
            }
            Err(err) => {
                log::warn!("发送本地通知失败：{err}");
                mark_status(db, row.id, "failed", Some(&now_iso())).await?;
            }
        }
    }

    Ok(sent)
}

async fn notification_log_row(
    db: &DatabaseConnection,
    today_str: &str,
) -> AppResult<Vec<notification_log::Model>> {
    let rows = notification_log::Entity::find()
        .filter(notification_log::Column::Status.eq("scheduled"))
        .filter(notification_log::Column::ScheduledDate.lte(today_str))
        .order_by_asc(notification_log::Column::ScheduledDate)
        .order_by_asc(notification_log::Column::Id)
        .all(db)
        .await?;
    Ok(rows)
}

async fn due_time_for(target_type: &str, db: &DatabaseConnection) -> String {
    let result = match target_type {
        TARGET_LENS => settings::lens_reminder(db).await.map(|s| s.reminder_time),
        TARGET_CARE_CHANGE => care::get_state(db).await.map(|s| s.change.reminder_time),
        TARGET_CARE_EXPIRY => care::get_state(db).await.map(|s| s.expiry.reminder_time),
        _ => Ok("09:00".to_string()),
    };
    result.unwrap_or_else(|_| "09:00".to_string())
}

async fn mark_status(
    db: &DatabaseConnection,
    id: i32,
    status: &str,
    sent_at: Option<&str>,
) -> AppResult<()> {
    db.execute_raw(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE notification_logs SET status = ?, sent_at = ? WHERE id = ?",
        vec![status.into(), sent_at.into(), id.into()],
    ))
    .await?;
    Ok(())
}

/// 把「计划日期 + 提醒时间」转成本地时区的毫秒时间戳。
#[allow(dead_code)] // 仅在 Android 上使用
fn planned_millis(scheduled_date: &str, reminder_time: &str) -> Option<i64> {
    let date = NaiveDate::parse_from_str(scheduled_date.trim(), "%Y-%m-%d").ok()?;
    let (hour, minute) = reminder_time.trim().split_once(':')?;
    let hour: u32 = hour.parse().ok()?;
    let minute: u32 = minute.parse().ok()?;
    let naive = date.and_hms_opt(hour, minute, 0)?;
    Local
        .from_local_datetime(&naive)
        .single()
        .or_else(|| Local.from_local_datetime(&naive).earliest())
        .map(|value| value.timestamp_millis())
}

#[cfg(target_os = "android")]
fn native_scheduled_contains(id: i32) -> bool {
    NATIVE_SCHEDULED
        .lock()
        .ok()
        .and_then(|guard| guard.as_ref().map(|set| set.contains(&id)))
        .unwrap_or(false)
}

#[cfg(not(target_os = "android"))]
fn native_scheduled_contains(_id: i32) -> bool {
    false
}

/// 重新排定系统闹钟：先全部取消，再把「还没到点」的计划逐条交给系统。
#[cfg(target_os = "android")]
async fn sync_native_schedule(db: &DatabaseConnection) -> AppResult<()> {
    if let Err(err) = reminder_mobile::cancel_all() {
        log::warn!("取消旧的系统闹钟失败：{err}");
    }

    let rows = notification_log::Entity::find()
        .filter(notification_log::Column::Status.eq("scheduled"))
        .all(db)
        .await?;

    let now = Local::now().timestamp_millis();
    let mut scheduled: std::collections::HashSet<i32> = std::collections::HashSet::new();

    for row in rows {
        let reminder_time = due_time_for(&row.target_type, db).await;
        let Some(at) = planned_millis(&row.scheduled_date, &reminder_time) else {
            continue;
        };
        // 已过点的交给前台轮询立即补发，系统闹钟只负责未来
        if at <= now + 2_000 {
            continue;
        }
        match reminder_mobile::schedule(row.id, &row.title, &row.body, at) {
            Ok(()) => {
                scheduled.insert(row.id);
            }
            Err(err) => log::warn!("排定系统闹钟失败（日志 {}）：{err}", row.id),
        }
    }

    if let Ok(mut guard) = NATIVE_SCHEDULED.lock() {
        *guard = Some(scheduled);
    }
    Ok(())
}

#[cfg(not(target_os = "android"))]
async fn sync_native_schedule(_db: &DatabaseConnection) -> AppResult<()> {
    Ok(())
}

/// 取消所有待触发计划（关闭总开关时调用）。
pub async fn cancel_all(db: &DatabaseConnection) -> AppResult<()> {
    if reminder_mobile::is_supported() {
        let _ = reminder_mobile::cancel_all();
        #[cfg(target_os = "android")]
        if let Ok(mut guard) = NATIVE_SCHEDULED.lock() {
            *guard = Some(Default::default());
        }
    }
    db.execute_raw(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "UPDATE notification_logs SET status = 'cancelled' WHERE status = 'scheduled'",
        vec![],
    ))
    .await?;
    Ok(())
}

pub async fn logs(db: &DatabaseConnection, limit: u32) -> AppResult<Vec<NotificationLogDto>> {
    let rows = notification_log::Entity::find()
        .order_by_desc(notification_log::Column::ScheduledDate)
        .order_by_desc(notification_log::Column::Id)
        .limit(limit.max(1) as u64)
        .all(db)
        .await?;

    Ok(rows
        .into_iter()
        .map(|row| NotificationLogDto {
            id: row.id,
            notification_key: row.notification_key,
            target_type: row.target_type,
            target_id: row.target_id,
            scheduled_date: row.scheduled_date,
            sent_at: row.sent_at,
            status: row.status,
            title: row.title,
            body: row.body,
        })
        .collect())
}

/// 启动时初始化：在后台线程中启动每分钟检查。
pub fn spawn_ticker(app: AppHandle) {
    tauri::async_runtime::spawn(async move {
        loop {
            tokio::time::sleep(std::time::Duration::from_secs(60)).await;
            let Some(db) = app.try_state::<crate::AppState>() else {
                continue;
            };
            if let Err(err) = tick(&app, &db.db).await {
                log::warn!("通知轮询失败：{err}");
            }
        }
    });
}
