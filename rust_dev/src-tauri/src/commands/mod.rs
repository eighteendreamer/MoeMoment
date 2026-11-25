//! Tauri 命令层：薄封装，只做参数转换、调用服务与通知重排。

pub mod care;
pub mod lens;
pub mod system;

use tauri::{AppHandle, Manager};

use crate::error::AppResult;
use crate::services::notification;
use crate::AppState;

/// 数据变更后重排通知。通知失败不回滚业务数据，但要记录日志。
pub async fn replan(app: &AppHandle) {
    let Some(state) = app.try_state::<AppState>() else {
        return;
    };
    let db = state.db.clone();
    if let Err(err) = notification::reload_plans(app, &db).await {
        log::warn!("重排通知失败：{err}");
    }
}

/// 供 setup 阶段使用：启动后立刻重排一次，补上应用未运行期间的计划。
pub async fn bootstrap_notifications(app: AppHandle) -> AppResult<()> {
    let state = app
        .try_state::<AppState>()
        .ok_or_else(|| crate::error::AppError::msg("应用状态未初始化"))?;
    let db = state.db.clone();
    notification::reload_plans(&app, &db).await
}
