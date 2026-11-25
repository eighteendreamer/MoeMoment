//! 美瞳相关命令。

use tauri::{AppHandle, State};

use crate::AppState;
use crate::dto::{
    CycleDto, CycleUpsert, HomeOverview, LensDto, LensFilter, LensUpsert, OpenLensRequest,
};
use crate::error::AppResult;
use crate::services::{cycle, lens};

#[tauri::command]
pub async fn list_lenses(
    state: State<'_, AppState>,
    filter: Option<LensFilter>,
) -> AppResult<Vec<LensDto>> {
    lens::list(&state.db, filter.unwrap_or_default()).await
}

#[tauri::command]
pub async fn get_lens(state: State<'_, AppState>, id: i32) -> AppResult<LensDto> {
    lens::get(&state.db, id).await
}

#[tauri::command]
pub async fn create_lens(
    app: AppHandle,
    state: State<'_, AppState>,
    payload: LensUpsert,
) -> AppResult<LensDto> {
    let created = lens::create(&state.db, payload).await?;
    super::replan(&app).await;
    Ok(created)
}

#[tauri::command]
pub async fn update_lens(
    app: AppHandle,
    state: State<'_, AppState>,
    id: i32,
    payload: LensUpsert,
) -> AppResult<LensDto> {
    let updated = lens::update(&state.db, id, payload).await?;
    super::replan(&app).await;
    Ok(updated)
}

#[tauri::command]
pub async fn delete_lens(
    app: AppHandle,
    state: State<'_, AppState>,
    id: i32,
) -> AppResult<()> {
    lens::delete(&state.db, id).await?;
    super::replan(&app).await;
    Ok(())
}

#[tauri::command]
pub async fn open_lens(
    app: AppHandle,
    state: State<'_, AppState>,
    request: OpenLensRequest,
) -> AppResult<LensDto> {
    let updated = lens::open(&state.db, request.lens_id, request.opened_at).await?;
    super::replan(&app).await;
    Ok(updated)
}

#[tauri::command]
pub async fn discard_lens(
    app: AppHandle,
    state: State<'_, AppState>,
    id: i32,
) -> AppResult<LensDto> {
    let updated = lens::discard(&state.db, id).await?;
    super::replan(&app).await;
    Ok(updated)
}

#[tauri::command]
pub async fn restore_lens(
    app: AppHandle,
    state: State<'_, AppState>,
    id: i32,
) -> AppResult<LensDto> {
    let updated = lens::restore_unopened(&state.db, id).await?;
    super::replan(&app).await;
    Ok(updated)
}

#[tauri::command]
pub async fn home_overview(state: State<'_, AppState>) -> AppResult<HomeOverview> {
    lens::home_overview(&state.db).await
}

#[tauri::command]
pub async fn expiring_lenses(state: State<'_, AppState>) -> AppResult<Vec<LensDto>> {
    lens::expiring_list(&state.db).await
}

#[tauri::command]
pub async fn lens_colors(state: State<'_, AppState>) -> AppResult<Vec<String>> {
    lens::colors(&state.db).await
}

#[tauri::command]
pub async fn list_cycles(state: State<'_, AppState>) -> AppResult<Vec<CycleDto>> {
    cycle::list(&state.db).await
}

#[tauri::command]
pub async fn create_cycle(state: State<'_, AppState>, payload: CycleUpsert) -> AppResult<CycleDto> {
    cycle::create(&state.db, payload).await
}

#[tauri::command]
pub async fn update_cycle(
    state: State<'_, AppState>,
    id: i32,
    payload: CycleUpsert,
) -> AppResult<CycleDto> {
    cycle::update(&state.db, id, payload).await
}

#[tauri::command]
pub async fn delete_cycle(
    app: AppHandle,
    state: State<'_, AppState>,
    id: i32,
) -> AppResult<()> {
    cycle::delete(&state.db, id).await?;
    super::replan(&app).await;
    Ok(())
}
