//! MoeMoment 应用入口：初始化数据库、图片目录、通知与命令注册。

mod commands;
mod db;
mod domain;
mod dto;
mod error;
mod services;

use std::sync::Arc;

use sea_orm::DatabaseConnection;
use tauri::{Manager, RunEvent};

use crate::services::{media, notification};

/// 全局应用状态：数据库连接与关键路径。
pub struct AppState {
    pub db: Arc<DatabaseConnection>,
    pub db_path: std::path::PathBuf,
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let mut builder = tauri::Builder::default()
        .plugin(
            tauri_plugin_log::Builder::default()
                .level(log::LevelFilter::Info)
                .build(),
        )
        .plugin(tauri_plugin_notification::init());

    // Android 原生提醒插件（系统闹钟）；其它平台返回 None，改用前台轮询
    if let Some(reminder_plugin) = services::reminder_mobile::plugin() {
        builder = builder.plugin(reminder_plugin);
    }

    let app = builder
        .setup(|app| {
            let handle = app.handle().clone();

            let db_path = db::database_path(&handle)?;
            let images_dir = handle
                .path()
                .app_data_dir()
                .map_err(|err| anyhow::anyhow!("无法定位应用数据目录：{err}"))?
                .join("images");
            media::init(images_dir)?;

            let conn = tauri::async_runtime::block_on(db::connect(&db_path))?;
            tauri::async_runtime::block_on(db::init(&conn))?;

            app.manage(AppState {
                db: Arc::new(conn),
                db_path,
            });

            // 启动后立即重排一次提醒，补上应用未运行期间遗漏的计划
            let boot_handle = handle.clone();
            tauri::async_runtime::spawn(async move {
                if let Err(err) = commands::bootstrap_notifications(boot_handle).await {
                    log::warn!("启动时重排通知失败：{err}");
                }
            });

            // Windows：注册通知的应用标识，让通知头显示 MoeMoment 而不是宿主进程
            #[cfg(target_os = "windows")]
            if let Err(err) = services::windows_toast::ensure_registered(&handle) {
                log::warn!("注册通知标识失败：{err}");
            }

            notification::spawn_ticker(handle);

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::lens::list_lenses,
            commands::lens::get_lens,
            commands::lens::create_lens,
            commands::lens::update_lens,
            commands::lens::delete_lens,
            commands::lens::open_lens,
            commands::lens::discard_lens,
            commands::lens::restore_lens,
            commands::lens::home_overview,
            commands::lens::expiring_lenses,
            commands::lens::lens_colors,
            commands::lens::list_cycles,
            commands::lens::create_cycle,
            commands::lens::update_cycle,
            commands::lens::delete_cycle,
            commands::care::care_state,
            commands::care::care_bottles,
            commands::care::save_care_bottle,
            commands::care::update_care_change_reminder,
            commands::care::update_care_expiry_reminder,
            commands::care::mark_care_changed,
            commands::system::app_info,
            commands::system::get_app_settings,
            commands::system::set_app_setting,
            commands::system::lens_reminder_setting,
            commands::system::update_lens_reminder,
            commands::system::notification_permission,
            commands::system::request_notification_permission,
            commands::system::notification_logs,
            commands::system::reschedule_notifications,
            commands::system::check_update,
            commands::system::fetch_update_checksum,
            commands::system::download_update,
            commands::system::save_lens_image,
            commands::system::delete_lens_image,
        ])
        .build(tauri::generate_context!())
        .expect("启动 Tauri 应用失败");

    app.run(|handle, event| {
        // 回到前台时校验并补发提醒（移动端由系统在恢复时触发）
        if let RunEvent::Resumed = event {
            let handle = handle.clone();
            tauri::async_runtime::spawn(async move {
                if let Err(err) = commands::bootstrap_notifications(handle).await {
                    log::warn!("恢复前台时重排通知失败：{err}");
                }
            });
        }
    });
}
