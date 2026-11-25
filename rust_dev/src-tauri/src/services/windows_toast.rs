//! Windows 原生 Toast 通知。
//!
//! 为什么不用 tauri-plugin-notification：它在 Windows 上会**跳过**设置 AppUserModelID
//! （源码里判断 exe 位于 target/debug 或 target/release 就不设），于是开发运行时
//! 通知来源退化成「Windows PowerShell」，图标和名称都不是本应用。
//!
//! 这里直接调用 WinRT Toast，并显式使用本应用的 AUMID，同时在 HKCU 注册该 AUMID 的
//! 显示名与图标，使通知头部、通知中心和操作中心都显示 MoeMoment。

#![cfg(target_os = "windows")]

use std::path::PathBuf;
use std::sync::OnceLock;

use tauri::{AppHandle, Manager};
use tauri_winrt_notification::{IconCrop, Sound, Toast};
use winreg::enums::HKEY_CURRENT_USER;
use winreg::RegKey;

/// 必须与 tauri.conf.json 的 identifier 一致
pub const APP_ID: &str = "com.moemoment.app";
const DISPLAY_NAME: &str = "MoeMoment";

static ICON_PATH: OnceLock<PathBuf> = OnceLock::new();

/// 启动时调用：落一份通知图标到应用数据目录，并注册 AUMID。
pub fn ensure_registered(app: &AppHandle) -> Result<(), String> {
    let dir = app
        .path()
        .app_data_dir()
        .map_err(|err| format!("无法定位应用数据目录：{err}"))?;
    std::fs::create_dir_all(&dir).map_err(|err| err.to_string())?;

    let icon = dir.join("notification-icon.png");
    if !icon.exists() {
        std::fs::write(&icon, include_bytes!("../../icons/128x128.png"))
            .map_err(|err| format!("写入通知图标失败：{err}"))?;
    }

    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    let (key, _) = hkcu
        .create_subkey(format!("Software\\Classes\\AppUserModelId\\{APP_ID}"))
        .map_err(|err| format!("注册通知标识失败：{err}"))?;

    key.set_value("DisplayName", &DISPLAY_NAME)
        .map_err(|err| format!("写入通知名称失败：{err}"))?;
    key.set_value("IconUri", &icon.to_string_lossy().to_string())
        .map_err(|err| format!("写入通知图标失败：{err}"))?;
    // 让应用出现在系统「通知和操作」列表里
    let _ = key.set_value("ShowInSettings", &1u32);

    let _ = ICON_PATH.set(icon);
    Ok(())
}

/// 发送一条系统通知。标题即通知头，正文放在第一行。
pub fn show(title: &str, body: &str) -> Result<(), String> {
    let mut toast = Toast::new(APP_ID).title(title).text1(body);

    if let Some(icon) = ICON_PATH.get() {
        toast = toast.icon(icon, IconCrop::Circular, DISPLAY_NAME);
    }

    toast
        .sound(Some(Sound::Default))
        .show()
        .map_err(|err| err.to_string())
}
