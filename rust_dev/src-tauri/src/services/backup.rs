//! 数据备份：导出 / 导入。
//!
//! 备份文件是一个 zip：`data.json`（全部业务表 + schema 版本）+ `images/`（美瞳照片）。
//! 导入前自动把当前数据备份到应用数据目录（保留最近 3 份），导入失败不影响现有数据。

use std::io::{Read, Write};
use std::path::{Path, PathBuf};

use sea_orm::{
    ColumnTrait, DatabaseConnection, EntityTrait, IntoActiveModel, QueryFilter, QueryOrder,
    TransactionTrait,
};
use serde::{Deserialize, Serialize};

use crate::db::entities::{
    app_setting, care_bottle, care_change_log, care_change_reminder, care_expiry_setting, lens,
    lens_cycle, lens_expiry_setting, lens_image,
};
use crate::error::{AppError, AppResult};

/// 备份格式版本：表结构升级时递增，导入时按此识别并做兼容处理。
pub const SCHEMA_VERSION: u32 = 1;
/// 应用数据目录里自动备份的保留份数。
const AUTO_BACKUP_KEEP: usize = 3;

#[derive(Serialize, Deserialize)]
pub struct BackupData {
    pub schema_version: u32,
    /// 导出时间（本地时区，ISO 格式），仅用于展示。
    pub created_at: String,
    pub lenses: Vec<lens::Model>,
    pub lens_images: Vec<lens_image::Model>,
    pub lens_cycles: Vec<lens_cycle::Model>,
    pub care_bottles: Vec<care_bottle::Model>,
    pub care_change_logs: Vec<care_change_log::Model>,
    pub lens_expiry_settings: Vec<lens_expiry_setting::Model>,
    pub care_change_settings: Vec<care_change_reminder::Model>,
    pub care_expiry_settings: Vec<care_expiry_setting::Model>,
    pub app_settings: Vec<app_setting::Model>,
}

/// 导入结果摘要（回显给用户确认用了多少数据）。
#[derive(Serialize)]
pub struct ImportSummary {
    pub lenses: usize,
    pub images: usize,
    pub cycles: usize,
    pub care_bottles: usize,
    /// 导入前自动备份的文件名，出问题可以再导回去。
    pub auto_backup: Option<String>,
}

fn now_iso() -> String {
    chrono::Local::now().format("%Y-%m-%d %H:%M:%S").to_string()
}

fn backup_stamp() -> String {
    chrono::Local::now().format("%Y%m%d-%H%M%S").to_string()
}

/// 从数据库收集全部业务数据。
async fn collect(db: &DatabaseConnection) -> AppResult<BackupData> {
    Ok(BackupData {
        schema_version: SCHEMA_VERSION,
        created_at: now_iso(),
        lenses: lens::Entity::find().all(db).await?,
        lens_images: lens_image::Entity::find().all(db).await?,
        lens_cycles: lens_cycle::Entity::find().order_by_asc(lens_cycle::Column::Id).all(db).await?,
        care_bottles: care_bottle::Entity::find().all(db).await?,
        care_change_logs: care_change_log::Entity::find().all(db).await?,
        lens_expiry_settings: lens_expiry_setting::Entity::find().all(db).await?,
        care_change_settings: care_change_reminder::Entity::find().all(db).await?,
        care_expiry_settings: care_expiry_setting::Entity::find().all(db).await?,
        app_settings: app_setting::Entity::find().all(db).await?,
    })
}

/// 组装 zip 字节流。图片按文件名收进 `images/`，路径在 data.json 里保持原样，
/// 由导入方负责重写（不同设备的应用数据目录不同）。
fn build_zip(data: &BackupData, images_dir: &Path) -> AppResult<Vec<u8>> {
    let json = serde_json::to_vec_pretty(data)
        .map_err(|err| AppError::msg(format!("数据序列化失败：{err}")))?;

    let mut zip = zip::ZipWriter::new(std::io::Cursor::new(Vec::new()));
    let options =
        zip::write::SimpleFileOptions::default().compression_method(zip::CompressionMethod::Deflated);
    zip.start_file("data.json", options.clone())
        .map_err(|err| AppError::msg(format!("打包失败：{err}")))?;
    zip.write_all(&json).map_err(|err| AppError::msg(err.to_string()))?;

    for image in &data.lens_images {
        let file_name = image
            .image_path
            .rsplit(['/', '\\'])
            .next()
            .unwrap_or_default()
            .to_string();
        if file_name.is_empty() {
            continue;
        }
        let Ok(bytes) = std::fs::read(images_dir.join(&file_name)) else {
            // 照片文件可能已被手动删除：跳过，不让整个导出失败
            continue;
        };
        zip.start_file(format!("images/{file_name}"), options.clone())
            .map_err(|err| AppError::msg(format!("打包失败：{err}")))?;
        zip.write_all(&bytes).map_err(|err| AppError::msg(err.to_string()))?;
    }

    let cursor = zip.finish().map_err(|err| AppError::msg(format!("打包失败：{err}")))?;
    Ok(cursor.into_inner())
}

/// 导出当前全部数据到指定目录，返回 zip 的绝对路径。
pub async fn export_backup(db: &DatabaseConnection, out_dir: &Path) -> AppResult<PathBuf> {
    std::fs::create_dir_all(out_dir)?;
    let images_dir = crate::services::media::images_dir_global()?;
    let data = collect(db).await?;
    let bytes = build_zip(&data, &images_dir)?;

    let file_name = format!("偶尔萌-backup-{}.zip", backup_stamp());
    let target = out_dir.join(&file_name);
    std::fs::write(&target, &bytes)?;
    Ok(target)
}

/// 把当前数据备份到应用数据目录（导入前自动执行），并清理旧备份。
async fn auto_backup_current(db: &DatabaseConnection, backups_dir: &Path) -> AppResult<Option<String>> {
    std::fs::create_dir_all(backups_dir)?;
    let images_dir = crate::services::media::images_dir_global()?;
    let data = collect(db).await?;

    // 空库不必备份（新装应用第一次导入）
    let has_custom = data.lens_cycles.iter().any(|cycle| !cycle.is_builtin);
    if data.lenses.is_empty() && data.care_bottles.is_empty() && !has_custom {
        return Ok(None);
    }

    let bytes = build_zip(&data, &images_dir)?;
    let file_name = format!("auto-backup-{}.zip", backup_stamp());
    std::fs::write(backups_dir.join(&file_name), &bytes)?;

    // 只保留最近 N 份
    let mut entries: Vec<PathBuf> = std::fs::read_dir(backups_dir)?
        .filter_map(|entry| entry.ok().map(|e| e.path()))
        .filter(|path| path.extension().is_some_and(|ext| ext == "zip"))
        .collect();
    entries.sort();
    while entries.len() > AUTO_BACKUP_KEEP {
        let oldest = entries.remove(0);
        let _ = std::fs::remove_file(oldest);
    }
    Ok(Some(file_name))
}

/// 解析 zip，返回数据与解出来的图片（文件名 → 字节）。
fn parse_zip(bytes: &[u8]) -> AppResult<(BackupData, Vec<(String, Vec<u8>)>)> {
    let reader = std::io::Cursor::new(bytes);
    let mut archive = zip::ZipArchive::new(reader)
        .map_err(|err| AppError::msg(format!("无法读取备份文件：{err}")))?;

    let mut json_bytes = None;
    let mut images = Vec::new();
    for index in 0..archive.len() {
        let mut file = archive
            .by_index(index)
            .map_err(|err| AppError::msg(format!("备份文件损坏：{err}")))?;
        let name = file.name().to_string();
        if name == "data.json" {
            let mut buffer = Vec::new();
            file.read_to_end(&mut buffer).map_err(|err| AppError::msg(err.to_string()))?;
            json_bytes = Some(buffer);
        } else if let Some(file_name) = name.strip_prefix("images/") {
            if file_name.contains("..") || file_name.contains('/') || file_name.contains('\\') {
                continue;
            }
            let mut buffer = Vec::new();
            file.read_to_end(&mut buffer).map_err(|err| AppError::msg(err.to_string()))?;
            images.push((file_name.to_string(), buffer));
        }
    }

    let json_bytes = json_bytes.ok_or_else(|| AppError::msg("备份文件里没有 data.json，不是本应用的备份"))?;
    let data: BackupData = serde_json::from_slice(&json_bytes)
        .map_err(|err| AppError::msg(format!("备份格式无法识别：{err}")))?;
    if data.schema_version > SCHEMA_VERSION {
        return Err(AppError::msg(format!(
            "备份来自更高版本（格式 v{}），请先升级应用",
            data.schema_version
        )));
    }
    Ok((data, images))
}

/// 覆盖导入：替换现有全部数据。返回导入摘要。
pub async fn import_backup(
    db: &DatabaseConnection,
    backups_dir: &Path,
    bytes: &[u8],
) -> AppResult<ImportSummary> {
    let (data, images) = parse_zip(bytes)?;
    let images_dir = crate::services::media::images_dir_global()?;
    std::fs::create_dir_all(&images_dir)?;

    let auto_backup = auto_backup_current(db, backups_dir).await?;

    let txn = db.begin().await?;

    // 清空现有业务数据（顺序保证不触发外键约束）
    lens_image::Entity::delete_many().exec(&txn).await?;
    lens::Entity::delete_many().exec(&txn).await?;
    care_change_log::Entity::delete_many().exec(&txn).await?;
    care_bottle::Entity::delete_many().exec(&txn).await?;
    lens_cycle::Entity::delete_many()
        .filter(lens_cycle::Column::IsBuiltin.eq(false))
        .exec(&txn)
        .await?;

    // 内置周期可能被用户删过或来自旧备份，按 id 全量恢复
    for model in &data.lens_cycles {
        lens_cycle::Entity::insert(model.clone().into_active_model())
            .on_conflict(
                sea_orm::sea_query::OnConflict::column(lens_cycle::Column::Id)
                    .update_columns([
                        lens_cycle::Column::CycleName,
                        lens_cycle::Column::CycleUnit,
                        lens_cycle::Column::CycleValue,
                        lens_cycle::Column::IsBuiltin,
                        lens_cycle::Column::SortOrder,
                        lens_cycle::Column::CreatedAt,
                    ])
                    .to_owned(),
            )
            .exec(&txn)
            .await?;
    }
    for model in &data.lenses {
        lens::Entity::insert(model.clone().into_active_model()).exec(&txn).await?;
    }
    for model in &data.lens_images {
        lens_image::Entity::insert(model.clone().into_active_model()).exec(&txn).await?;
    }
    for model in &data.care_bottles {
        care_bottle::Entity::insert(model.clone().into_active_model()).exec(&txn).await?;
    }
    for model in &data.care_change_logs {
        care_change_log::Entity::insert(model.clone().into_active_model()).exec(&txn).await?;
    }
    // 提醒设置：清掉本地再按备份恢复
    lens_expiry_setting::Entity::delete_many().exec(&txn).await?;
    for model in &data.lens_expiry_settings {
        lens_expiry_setting::Entity::insert(model.clone().into_active_model()).exec(&txn).await?;
    }
    care_change_reminder::Entity::delete_many().exec(&txn).await?;
    for model in &data.care_change_settings {
        care_change_reminder::Entity::insert(model.clone().into_active_model()).exec(&txn).await?;
    }
    care_expiry_setting::Entity::delete_many().exec(&txn).await?;
    for model in &data.care_expiry_settings {
        care_expiry_setting::Entity::insert(model.clone().into_active_model()).exec(&txn).await?;
    }
    for model in &data.app_settings {
        app_setting::Entity::insert(model.clone().into_active_model())
            .on_conflict(
                sea_orm::sea_query::OnConflict::column(app_setting::Column::Key)
                    .update_column(app_setting::Column::Value)
                    .to_owned(),
            )
            .exec(&txn)
            .await?;
    }

    txn.commit().await?;

    // 照片：复制到图片目录，id 冲突的照片保留本地已有文件
    let mut images_copied = 0usize;
    for (file_name, bytes) in &images {
        let target = images_dir.join(file_name);
        if !target.exists() {
            let _ = std::fs::write(&target, bytes);
        }
        images_copied += 1;
    }

    Ok(ImportSummary {
        lenses: data.lenses.len(),
        images: images_copied,
        cycles: data.lens_cycles.len(),
        care_bottles: data.care_bottles.len(),
        auto_backup,
    })
}

/// 应用数据目录里的自动备份列表（最新在前）。
pub fn list_auto_backups(backups_dir: &Path) -> Vec<String> {
    let Ok(entries) = std::fs::read_dir(backups_dir) else {
        return Vec::new();
    };
    let mut names: Vec<String> = entries
        .filter_map(|entry| entry.ok())
        .map(|entry| entry.file_name().to_string_lossy().to_string())
        .filter(|name| name.starts_with("auto-backup-") && name.ends_with(".zip"))
        .collect();
    names.sort();
    names.reverse();
    names
}

/// 读取自动备份文件内容（走同一条导入链路恢复）。
pub fn read_auto_backup(backups_dir: &Path, name: &str) -> AppResult<Vec<u8>> {
    // 只允许文件名，不允许路径穿越
    if name.contains('/') || name.contains('\\') || name.contains("..") {
        return Err(AppError::msg("非法的备份文件名"));
    }
    let path = backups_dir.join(name);
    if !path.is_file() {
        return Err(AppError::msg("备份不存在，可能已被清理"));
    }
    std::fs::read(&path).map_err(|err| AppError::msg(format!("读取备份失败：{err}")))
}

#[cfg(test)]
mod tests {
    use super::*;
    use sea_orm::{ActiveModelTrait, Set};
    use crate::db;

    async fn fresh_db(dir: &Path) -> DatabaseConnection {
        let _ = std::fs::remove_dir_all(dir);
        std::fs::create_dir_all(dir).unwrap();
        // 备份流程会读图片目录，测试里指向临时目录
        crate::services::media::init(dir.join("images")).unwrap();
        let db = db::connect(&dir.join("test.sqlite3")).await.unwrap();
        db::init(&db).await.unwrap();
        db
    }

    /// 导出 → 清空 → 导入：数据必须完整回来（含内置周期与自定义周期）。
    #[tokio::test]
    async fn export_import_roundtrip() {
        let dir = std::env::temp_dir().join("moemoment_backup_test");
        let db = fresh_db(&dir).await;

        // 一条自定义周期 + 一副美瞳
        let cycle = lens_cycle::ActiveModel {
            cycle_name: Set("测试周期".to_string()),
            cycle_unit: Set("day".to_string()),
            cycle_value: Set(30),
            is_builtin: Set(false),
            sort_order: Set(99),
            created_at: Set("2026-01-01T00:00:00".to_string()),
            ..Default::default()
        };
        let cycle_id = lens_cycle::Entity::insert(cycle).exec(&db).await.unwrap().last_insert_id;
        let lens = lens::ActiveModel {
            brand: Set("测试品牌".to_string()),
            name: Set("往返测试".to_string()),
            cycle_id: Set(cycle_id),
            status: Set("unopened".to_string()),
            created_at: Set("2026-01-01T00:00:00".to_string()),
            updated_at: Set("2026-01-01T00:00:00".to_string()),
            ..Default::default()
        };
        lens::Entity::insert(lens).exec(&db).await.unwrap();

        // 导出
        let out_dir = dir.join("out");
        let zip_path = export_backup(&db, &out_dir).await.unwrap();
        assert!(zip_path.is_file());
        let bytes = std::fs::read(&zip_path).unwrap();

        // 清空自定义数据
        lens::Entity::delete_many().exec(&db).await.unwrap();
        lens_cycle::Entity::delete_many()
            .filter(lens_cycle::Column::IsBuiltin.eq(false))
            .exec(&db)
            .await
            .unwrap();
        assert_eq!(lens::Entity::find().all(&db).await.unwrap().len(), 0);

        // 导入
        let backups_dir = dir.join("backups");
        let summary = import_backup(&db, &backups_dir, &bytes).await.unwrap();
        assert_eq!(summary.lenses, 1);
        assert_eq!(summary.cycles, 7, "6 内置 + 1 自定义");
        // 当前数据只剩内置周期（美瞳已被清空），无需备份
        assert!(summary.auto_backup.is_none(), "空数据时不应生成备份");

        let lenses = lens::Entity::find().all(&db).await.unwrap();
        assert_eq!(lenses.len(), 1);
        assert_eq!(lenses[0].name, "往返测试");

        // 自定义周期回来了
        let cycles = lens_cycle::Entity::find()
            .filter(lens_cycle::Column::IsBuiltin.eq(false))
            .all(&db)
            .await
            .unwrap();
        assert_eq!(cycles.len(), 1);
        assert_eq!(cycles[0].cycle_name, "测试周期");
    }

    /// 损坏的 zip 必须报错且不影响现有数据。
    #[tokio::test]
    async fn broken_zip_is_rejected() {
        let dir = std::env::temp_dir().join("moemoment_backup_broken");
        let db = fresh_db(&dir).await;
        let backups_dir = dir.join("backups");

        let err = import_backup(&db, &backups_dir, b"not a zip").await;
        assert!(err.is_err());
        // 数据未被破坏（内置周期还在）
        assert_eq!(lens_cycle::Entity::find().all(&db).await.unwrap().len(), 6);
    }
}
