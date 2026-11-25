//! 前后端契约：请求参数与返回结构。字段统一 camelCase 给 React 使用。

use serde::{Deserialize, Serialize};

/// 镜片参数。JSON 键名按需求保留原始拼写，6 项均可缺失。
#[derive(Clone, Debug, Default, Serialize, Deserialize, PartialEq)]
pub struct LensSpecs {
    #[serde(rename = "Lens_diameter", default, skip_serializing_if = "Option::is_none")]
    pub lens_diameter: Option<f64>,
    #[serde(rename = "Colored_diameter", default, skip_serializing_if = "Option::is_none")]
    pub colored_diameter: Option<f64>,
    #[serde(rename = "Moisture_content", default, skip_serializing_if = "Option::is_none")]
    pub moisture_content: Option<f64>,
    #[serde(rename = "Base_arc", default, skip_serializing_if = "Option::is_none")]
    pub base_arc: Option<f64>,
    #[serde(rename = "Left_eye_prescription", default, skip_serializing_if = "Option::is_none")]
    pub left_eye_prescription: Option<f64>,
    #[serde(rename = "right_eye_prescription", default, skip_serializing_if = "Option::is_none")]
    pub right_eye_prescription: Option<f64>,
}

impl LensSpecs {
    /// 解析数据库中的 JSON 文本，非法或不完整时退回默认值，不影响整条记录展示。
    pub fn parse(raw: Option<&str>) -> Self {
        raw.and_then(|text| {
            if text.trim().is_empty() {
                None
            } else {
                serde_json::from_str::<LensSpecs>(text).ok()
            }
        })
        .unwrap_or_default()
    }

    /// 序列化为存储文本；全空时返回 None，避免写入无意义的 `{}`。
    pub fn to_storage(&self) -> Option<String> {
        if *self == Self::default() {
            return None;
        }
        serde_json::to_string(self).ok()
    }
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LensImageDto {
    pub id: i32,
    pub path: String,
    pub sort_order: i32,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LensDto {
    pub id: i32,
    pub brand: String,
    pub name: String,
    pub cycle_id: i32,
    pub cycle_name: String,
    pub cycle_unit: String,
    pub cycle_value: i32,
    pub color_scheme: Option<String>,
    pub lens_specs: LensSpecs,
    pub status: String,
    /// 推导状态：unopened / in_use / expired / discarded
    pub state: String,
    pub expiry_date: Option<String>,
    pub expiry_source: String,
    pub days_remaining: Option<i64>,
    pub is_expiring_soon: bool,
    pub opened_at: Option<String>,
    pub package_expiry_date: Option<String>,
    pub discarded_at: Option<String>,
    pub note: Option<String>,
    pub images: Vec<LensImageDto>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Clone, Debug, Default, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct HomeStats {
    pub in_use: u32,
    pub unopened: u32,
    pub expired: u32,
    pub total: u32,
    pub discarded: u32,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct HomeOverview {
    pub expiring: Vec<LensDto>,
    pub expired: Vec<LensDto>,
    pub recent: Vec<LensDto>,
    pub stats: HomeStats,
    pub advance_days: i32,
    pub lens_reminder_enabled: bool,
}

#[derive(Clone, Debug, Default, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LensFilter {
    pub keyword: Option<String>,
    pub cycle_id: Option<i32>,
    /// unopened / in_use / expired / discarded / all
    pub state: Option<String>,
    pub color_scheme: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LensUpsert {
    pub brand: String,
    pub name: String,
    pub cycle_id: i32,
    pub color_scheme: Option<String>,
    pub lens_specs: Option<LensSpecs>,
    pub package_expiry_date: Option<String>,
    pub note: Option<String>,
    /// 已持久化的图片相对路径，顺序即展示顺序
    #[serde(default)]
    pub images: Vec<String>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OpenLensRequest {
    pub lens_id: i32,
    /// 用户确认的开封日期（YYYY-MM-DD），为空时取今天
    pub opened_at: Option<String>,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CycleDto {
    pub id: i32,
    pub cycle_name: String,
    pub cycle_unit: String,
    pub cycle_value: i32,
    pub is_builtin: bool,
    pub sort_order: i32,
    pub lens_count: u32,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CycleUpsert {
    pub cycle_name: String,
    pub cycle_unit: String,
    pub cycle_value: i32,
    pub sort_order: Option<i32>,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LensReminderSettingDto {
    pub is_active: bool,
    pub advance_days: i32,
    pub reminder_time: String,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LensReminderSettingInput {
    pub is_active: bool,
    pub advance_days: i32,
    pub reminder_time: String,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CareChangeReminderDto {
    pub is_active: bool,
    pub frequency: String,
    pub interval_days: i32,
    pub reminder_time: String,
    pub last_changed_date: Option<String>,
    pub next_changed_date: Option<String>,
    /// 距离下次更换的天数，负数表示已逾期
    pub days_until_next: Option<i64>,
    pub history: Vec<CareChangeLogDto>,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CareChangeLogDto {
    pub id: i32,
    pub changed_at: String,
    pub note: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CareChangeReminderInput {
    pub is_active: bool,
    pub frequency: String,
    pub interval_days: i32,
    pub reminder_time: String,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CareExpiryReminderDto {
    pub is_active: bool,
    pub advance_days: i32,
    pub reminder_time: String,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CareExpiryReminderInput {
    pub is_active: bool,
    pub advance_days: i32,
    pub reminder_time: String,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CareBottleDto {
    pub id: i32,
    pub brand: String,
    pub name: String,
    pub opened_at: Option<String>,
    pub package_expiry_date: Option<String>,
    pub after_open_valid_days: Option<i32>,
    pub is_current: bool,
    pub note: Option<String>,
    pub expiry_date: Option<String>,
    pub days_remaining: Option<i64>,
    pub expired: bool,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CareBottleInput {
    pub id: Option<i32>,
    pub brand: String,
    pub name: String,
    pub opened_at: Option<String>,
    pub package_expiry_date: Option<String>,
    pub after_open_valid_days: Option<i32>,
    pub is_current: bool,
    pub note: Option<String>,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CareStateDto {
    pub change: CareChangeReminderDto,
    pub expiry: CareExpiryReminderDto,
    pub bottle: Option<CareBottleDto>,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct NotificationLogDto {
    pub id: i32,
    pub notification_key: String,
    pub target_type: String,
    pub target_id: Option<i32>,
    pub scheduled_date: String,
    pub sent_at: Option<String>,
    pub status: String,
    pub title: String,
    pub body: String,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct NotificationPermissionDto {
    pub granted: bool,
    pub can_request: bool,
    /// 平台说明，用于如实告知后台调度限制
    pub platform_note: String,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AppSettingsDto {
    pub system_notifications_enabled: bool,
    pub auto_update_enabled: bool,
    pub github_mirror_mode: String,
    pub update_channel: String,
    pub last_update_check_at: Option<String>,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AppInfoDto {
    pub version: String,
    pub identifier: String,
    pub platform: String,
    pub arch: String,
    pub database_path: String,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateAssetDto {
    pub name: String,
    pub url: String,
    pub size: u64,
    pub content_type: Option<String>,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateInfoDto {
    pub current_version: String,
    pub latest_version: Option<String>,
    pub has_update: bool,
    pub notes: Option<String>,
    pub published_at: Option<String>,
    pub release_url: Option<String>,
    /// 与当前平台匹配的安装包信息
    pub asset: Option<UpdateAssetDto>,
    /// Release 附带的校验文件（如 SHA256SUMS.txt），用于下载后比对
    pub checksum: Option<UpdateAssetDto>,
    /// 与平台对应的安装方式说明
    pub install_hint: String,
    /// 实际使用的下载源：official / mirror
    pub source: Option<String>,
    pub error: Option<String>,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DownloadResultDto {
    pub path: String,
    pub bytes: u64,
    pub sha256: String,
    pub verified: bool,
}
