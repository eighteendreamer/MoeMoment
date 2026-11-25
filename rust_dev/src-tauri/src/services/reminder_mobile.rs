//! Android 原生提醒调度桥接。
//!
//! Tauri 官方通知插件只支持「立即发送」，没有系统级定时能力。这里注册一个应用内
//! 原生插件（Kotlin：`ReminderPlugin`），通过 AlarmManager 把提醒交给系统，
//! 应用被关闭后仍能触发；重启后由 `BootReceiver` 从 SharedPreferences 恢复。
//!
//! 无原生实现的平台（桌面 / iOS）上所有函数都是空操作，调用方继续使用前台轮询。

// 同一套接口在不同平台上有一部分只在 Android 分支被调用
#![allow(dead_code)]

use serde::Serialize;

#[derive(Serialize)]
struct SchedulePayload<'a> {
    id: i32,
    title: &'a str,
    body: &'a str,
    /// 触发时刻（UTC 毫秒时间戳）
    at: i64,
}

#[cfg(target_os = "android")]
mod android {
    use std::sync::OnceLock;

    use tauri::plugin::{Builder as PluginBuilder, PluginHandle, TauriPlugin};
    use tauri::Wry;

    use super::SchedulePayload;

    static HANDLE: OnceLock<PluginHandle<Wry>> = OnceLock::new();

    /// 注册 Android 原生插件。必须在 `Builder` 阶段加入。
    pub fn plugin() -> Option<TauriPlugin<Wry>> {
        Some(
            PluginBuilder::new("mm-reminder")
                .setup(|_app, api| {
                    let handle = api.register_android_plugin("com.moemoment.app", "ReminderPlugin")?;
                    let _ = HANDLE.set(handle);
                    Ok(())
                })
                .build(),
        )
    }

    pub fn schedule(id: i32, title: &str, body: &str, at_millis: i64) -> Result<(), String> {
        let handle = HANDLE.get().ok_or_else(|| "提醒插件未初始化".to_string())?;
        handle
            .run_mobile_plugin::<serde_json::Value>(
                "schedule",
                SchedulePayload {
                    id,
                    title,
                    body,
                    at: at_millis,
                },
            )
            .map(|_| ())
            .map_err(|err| err.to_string())
    }

    pub fn cancel(id: i32) -> Result<(), String> {
        let handle = HANDLE.get().ok_or_else(|| "提醒插件未初始化".to_string())?;
        handle
            .run_mobile_plugin::<serde_json::Value>("cancel", serde_json::json!({ "id": id }))
            .map(|_| ())
            .map_err(|err| err.to_string())
    }

    pub fn cancel_all() -> Result<(), String> {
        let handle = HANDLE.get().ok_or_else(|| "提醒插件未初始化".to_string())?;
        handle
            .run_mobile_plugin::<serde_json::Value>("cancelAll", serde_json::json!({}))
            .map(|_| ())
            .map_err(|err| err.to_string())
    }

    pub fn notify(id: i32, title: &str, body: &str) -> Result<(), String> {
        let handle = HANDLE.get().ok_or_else(|| "提醒插件未初始化".to_string())?;
        handle
            .run_mobile_plugin::<serde_json::Value>(
                "notify",
                serde_json::json!({ "id": id, "title": title, "body": body }),
            )
            .map(|_| ())
            .map_err(|err| err.to_string())
    }
}

#[cfg(not(target_os = "android"))]
mod android {
    use tauri::plugin::TauriPlugin;
    use tauri::Wry;

    pub fn plugin() -> Option<TauriPlugin<Wry>> {
        None
    }

    pub fn schedule(_id: i32, _title: &str, _body: &str, _at_millis: i64) -> Result<(), String> {
        Ok(())
    }

    pub fn cancel(_id: i32) -> Result<(), String> {
        Ok(())
    }

    pub fn cancel_all() -> Result<(), String> {
        Ok(())
    }

    pub fn notify(_id: i32, _title: &str, _body: &str) -> Result<(), String> {
        Ok(())
    }
}

/// 当前平台是否具备系统级定时能力。
pub fn is_supported() -> bool {
    cfg!(target_os = "android")
}

pub fn schedule(id: i32, title: &str, body: &str, at_millis: i64) -> Result<(), String> {
    android::schedule(id, title, body, at_millis)
}

pub fn cancel(id: i32) -> Result<(), String> {
    android::cancel(id)
}

pub fn cancel_all() -> Result<(), String> {
    android::cancel_all()
}

/// 立即通知：Android 复用同一个通知渠道与图标，保证前台/后台样式一致。
pub fn notify(id: i32, title: &str, body: &str) -> Result<(), String> {
    android::notify(id, title, body)
}

/// 在 `Builder` 阶段注册插件（非 Android 平台返回 None，不加入插件链）。
pub fn plugin() -> Option<tauri::plugin::TauriPlugin<tauri::Wry>> {
    android::plugin()
}
