//! 设置、通知、更新、图片与应用信息相关命令。

use tauri::{AppHandle, Manager, State};

use crate::AppState;
use crate::dto::{
    AppInfoDto, AppSettingsDto, DownloadResultDto, LensReminderSettingDto, LensReminderSettingInput,
    NotificationLogDto, NotificationPermissionDto, UpdateInfoDto,
};
use crate::error::{AppError, AppResult};
use crate::services::updater::{self, UpdaterConfig};
use crate::services::{backup, media, notification, settings};

#[tauri::command]
pub async fn app_info(app: AppHandle, state: State<'_, AppState>) -> AppResult<AppInfoDto> {
    Ok(AppInfoDto {
        version: app.package_info().version.to_string(),
        identifier: app.config().identifier.clone(),
        platform: std::env::consts::OS.to_string(),
        arch: std::env::consts::ARCH.to_string(),
        database_path: state.db_path.to_string_lossy().replace('\\', "/"),
    })
}

#[tauri::command]
pub async fn get_app_settings(state: State<'_, AppState>) -> AppResult<AppSettingsDto> {
    settings::get_app_settings(&state.db).await
}

#[tauri::command]
pub async fn set_app_setting(
    app: AppHandle,
    state: State<'_, AppState>,
    key: String,
    value: String,
) -> AppResult<AppSettingsDto> {
    let updated = settings::set_setting(&state.db, &key, &value).await?;

    // 通知总开关变化后必须重排/取消计划
    if key == settings::KEY_SYSTEM_NOTIFICATIONS {
        if updated.system_notifications_enabled {
            super::replan(&app).await;
        } else {
            notification::cancel_all(&state.db).await?;
        }
    }

    Ok(updated)
}

#[tauri::command]
pub async fn lens_reminder_setting(state: State<'_, AppState>) -> AppResult<LensReminderSettingDto> {
    settings::lens_reminder(&state.db).await
}

#[tauri::command]
pub async fn update_lens_reminder(
    app: AppHandle,
    state: State<'_, AppState>,
    payload: LensReminderSettingInput,
) -> AppResult<LensReminderSettingDto> {
    let updated = settings::update_lens_reminder(&state.db, payload).await?;
    super::replan(&app).await;
    Ok(updated)
}

#[tauri::command]
pub async fn notification_permission(app: AppHandle) -> AppResult<NotificationPermissionDto> {
    Ok(notification::permission_state(&app))
}

#[tauri::command]
pub async fn request_notification_permission(
    app: AppHandle,
    state: State<'_, AppState>,
) -> AppResult<NotificationPermissionDto> {
    let result = notification::request_permission(&app);
    let _ = settings::set_raw(&state.db, "notification_permission_prompted", "true").await;
    // 授权成功后补发今天应触发的提醒
    if result.granted {
        super::replan(&app).await;
    }
    Ok(result)
}

#[tauri::command]
pub async fn notification_logs(
    state: State<'_, AppState>,
    limit: Option<u32>,
) -> AppResult<Vec<NotificationLogDto>> {
    notification::logs(&state.db, limit.unwrap_or(30)).await
}

#[tauri::command]
pub async fn reschedule_notifications(
    app: AppHandle,
    state: State<'_, AppState>,
) -> AppResult<usize> {
    notification::reload_plans(&app, &state.db).await?;
    Ok(notification::tick(&app, &state.db).await?)
}

#[tauri::command]
pub async fn check_update(app: AppHandle, state: State<'_, AppState>) -> AppResult<UpdateInfoDto> {
    let current = app.package_info().version.to_string();
    let app_settings = settings::get_app_settings(&state.db).await?;

    let config = UpdaterConfig {
        owner: updater::GITHUB_OWNER.to_string(),
        repo: updater::GITHUB_REPO.to_string(),
        channel: app_settings.update_channel.clone(),
        mirror_mode: app_settings.github_mirror_mode.clone(),
    };

    let result = updater::check(&config, &current).await?;

    // 无论成功与否都记录检查时间，便于界面展示
    let _ = settings::set_raw(&state.db, settings::KEY_LAST_CHECK, &crate::domain::dates::now_iso()).await;

    Ok(result)
}

#[tauri::command]
pub async fn fetch_update_checksum(url: String) -> AppResult<String> {
    updater::fetch_checksum_text(&url).await
}

#[tauri::command]
pub async fn download_update(
    app: AppHandle,
    url: String,
    expected_sha256: Option<String>,
    file_name: String,
) -> AppResult<DownloadResultDto> {
    if !url.starts_with("https://") {
        return Err(AppError::msg("只允许通过 HTTPS 下载更新包"));
    }
    updater::download(&app, &url, expected_sha256.as_deref(), &file_name).await
}

/// 导出全部数据为 zip，返回绝对路径。Android 由前端继续调分享面板选择去向。
#[tauri::command]
pub async fn export_backup(app: AppHandle, state: State<'_, AppState>) -> AppResult<String> {
    let dir = app
        .path()
        .app_cache_dir()
        .map_err(|err| AppError::msg(format!("无法定位缓存目录：{err}")))?
        .join("export");
    let path = backup::export_backup(&state.db, &dir).await?;
    Ok(path.to_string_lossy().replace('\\', "/"))
}

/// 导入备份（覆盖现有数据，导入前自动备份）。数据以 base64 传入。
#[tauri::command]
pub async fn import_backup(
    app: AppHandle,
    state: State<'_, AppState>,
    data_base64: String,
) -> AppResult<serde_json::Value> {
    use base64::Engine;
    let dir = app
        .path()
        .app_data_dir()
        .map_err(|err| AppError::msg(format!("无法定位应用数据目录：{err}")))?
        .join("backups");
    let bytes = base64::engine::general_purpose::STANDARD
        .decode(data_base64.trim())
        .map_err(|err| AppError::msg(format!("备份数据解析失败：{err}")))?;
    if bytes.is_empty() {
        return Err(AppError::msg("备份内容为空"));
    }
    let summary = backup::import_backup(&state.db, &dir, &bytes).await?;
    Ok(serde_json::json!({
        "lenses": summary.lenses,
        "images": summary.images,
        "cycles": summary.cycles,
        "careBottles": summary.care_bottles,
        "autoBackup": summary.auto_backup,
    }))
}

/// Android：把导出的备份文件交给系统分享面板（微信 / QQ / 保存到文件等）。
#[tauri::command]
pub async fn share_file(path: String, mime: Option<String>) -> AppResult<()> {
    crate::services::reminder_mobile::share_file(&path, mime.as_deref().unwrap_or("application/zip"))
        .map_err(|err| AppError::msg(err))
        .map(|_| ())
}

/// Android：下载完成后拉起系统安装器。
#[tauri::command]
pub async fn install_apk(path: String) -> AppResult<()> {
    crate::services::reminder_mobile::install_apk(&path)
        .map_err(|err| AppError::msg(err))
        .map(|_| ())
}

#[tauri::command]
pub async fn save_lens_image(data: String, mime: Option<String>) -> AppResult<String> {
    media::save_base64_image(&data, mime.as_deref())
}

#[tauri::command]
pub async fn delete_lens_image(path: String) -> AppResult<()> {
    let dir = media::images_dir_global()?;
    media::delete_file(&dir, &path)
}
