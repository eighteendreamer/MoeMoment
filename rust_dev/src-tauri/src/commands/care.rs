//! 护理液相关命令。

use tauri::{AppHandle, State};

use crate::AppState;
use crate::dto::{
    CareBottleDto, CareBottleInput, CareChangeReminderInput, CareExpiryReminderInput, CareStateDto,
};
use crate::error::AppResult;
use crate::services::care;

#[tauri::command]
pub async fn care_state(state: State<'_, AppState>) -> AppResult<CareStateDto> {
    care::get_state(&state.db).await
}

#[tauri::command]
pub async fn care_bottles(state: State<'_, AppState>) -> AppResult<Vec<CareBottleDto>> {
    care::all_bottles(&state.db).await
}

#[tauri::command]
pub async fn save_care_bottle(
    app: AppHandle,
    state: State<'_, AppState>,
    payload: CareBottleInput,
) -> AppResult<CareStateDto> {
    let result = care::save_bottle(&state.db, payload).await?;
    super::replan(&app).await;
    Ok(result)
}

#[tauri::command]
pub async fn update_care_change_reminder(
    app: AppHandle,
    state: State<'_, AppState>,
    payload: CareChangeReminderInput,
) -> AppResult<CareStateDto> {
    let result = care::update_change_reminder(&state.db, payload).await?;
    super::replan(&app).await;
    Ok(result)
}

#[tauri::command]
pub async fn update_care_expiry_reminder(
    app: AppHandle,
    state: State<'_, AppState>,
    payload: CareExpiryReminderInput,
) -> AppResult<CareStateDto> {
    let result = care::update_expiry_reminder(&state.db, payload).await?;
    super::replan(&app).await;
    Ok(result)
}

#[tauri::command]
pub async fn mark_care_changed(
    app: AppHandle,
    state: State<'_, AppState>,
    changed_at: Option<String>,
    note: Option<String>,
) -> AppResult<CareStateDto> {
    let result = care::mark_changed(&state.db, changed_at, note).await?;
    super::replan(&app).await;
    Ok(result)
}
