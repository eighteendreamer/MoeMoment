//! 数据库连接、迁移与种子数据。
//!
//! 使用 SeaORM + SQLite，连接级开启外键约束（`PRAGMA foreign_keys`），
//! 迁移见 [`migrations`]，种子数据幂等（重复启动不覆盖用户配置）。

pub mod entities;
pub mod migrations;

use std::path::{Path, PathBuf};
use std::time::Duration;

use sea_orm::{
    ConnectOptions, ConnectionTrait, Database, DatabaseBackend, DatabaseConnection, Statement,
};
use sea_orm_migration::MigratorTrait;
use tauri::{AppHandle, Manager};

use crate::domain::dates::now_iso;

/// 数据库文件名。放在应用数据目录，随平台自动切换。
pub const DB_FILE_NAME: &str = "moemoment.sqlite3";

/// 解析数据库文件路径，并确保父目录存在。
pub fn database_path(app: &AppHandle) -> anyhow::Result<PathBuf> {
    let dir = app
        .path()
        .app_data_dir()
        .map_err(|err| anyhow::anyhow!("无法定位应用数据目录：{err}"))?;
    std::fs::create_dir_all(&dir)?;
    Ok(dir.join(DB_FILE_NAME))
}

/// 连接数据库。
///
/// 注意：这里通过 `map_sqlx_sqlite_opts` 直接指定文件路径，避免 Windows 盘符
/// 在 URL 里被错误解析；同时每个连接都会带上外键约束与 WAL 配置。
pub async fn connect(db_path: &Path) -> anyhow::Result<DatabaseConnection> {
    if let Some(parent) = db_path.parent() {
        std::fs::create_dir_all(parent)?;
    }

    let path = db_path.to_path_buf();
    // URL 只是 ConnectOptions 的占位（sqlite::memory: 会把连接标记为内存库，
    // 导致 DDL 与查询落在不同的内存实例上），真实文件由下面的闭包指定。
    let mut options = ConnectOptions::new("sqlite://moemoment.sqlite3".to_string());
    options
        .max_connections(4)
        .sqlx_logging(false)
        .map_sqlx_sqlite_opts(move |opts| {
            opts.filename(&path)
                .create_if_missing(true)
                .foreign_keys(true)
                .journal_mode(sea_orm::sqlx::sqlite::SqliteJournalMode::Wal)
                .synchronous(sea_orm::sqlx::sqlite::SqliteSynchronous::Normal)
                .busy_timeout(Duration::from_secs(5))
        });

    let db = Database::connect(options).await?;
    Ok(db)
}

/// 执行迁移 + 种子数据。
pub async fn init(db: &DatabaseConnection) -> anyhow::Result<()> {
    migrations::Migrator::up(db, None)
        .await
        .map_err(|err| anyhow::anyhow!("数据库迁移失败：{err}"))?;
    seed(db).await?;
    Ok(())
}

const BUILTIN_CYCLES: [(&str, &str, i32, i32); 6] = [
    ("日抛", "day", 1, 10),
    ("双周抛", "week", 2, 20),
    ("月抛", "month", 1, 30),
    ("季抛", "month", 3, 40),
    ("半年抛", "month", 6, 50),
    ("年抛", "year", 1, 60),
];

const DEFAULT_SETTINGS: [(&str, &str); 6] = [
    ("system_notifications_enabled", "true"),
    ("auto_update_enabled", "true"),
    ("github_mirror_mode", "auto"),
    ("update_channel", "stable"),
    ("last_update_check_at", ""),
    ("notification_permission_prompted", "false"),
];

/// 幂等种子：使用 INSERT OR IGNORE，不覆盖用户修改过的配置。
async fn seed(db: &DatabaseConnection) -> anyhow::Result<()> {
    let now = now_iso();

    for (name, unit, value, order) in BUILTIN_CYCLES {
        db.execute_raw(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "INSERT OR IGNORE INTO lens_cycles \
             (cycle_name, cycle_unit, cycle_value, is_builtin, sort_order, created_at) \
             VALUES (?, ?, ?, 1, ?, ?)",
            vec![
                name.into(),
                unit.into(),
                value.into(),
                order.into(),
                now.clone().into(),
            ],
        ))
        .await?;
    }

    // 单例配置（id = 1）：美瞳到期提醒、护理液更换提醒、护理液到期提醒
    db.execute_raw(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "INSERT OR IGNORE INTO lens_expiry_reminder_settings \
         (id, is_active, advance_days, reminder_time, updated_at) VALUES (1, 1, 3, '09:00', ?)",
        vec![now.clone().into()],
    ))
    .await?;

    db.execute_raw(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "INSERT OR IGNORE INTO care_solution_change_reminders \
         (id, is_active, frequency, interval_days, reminder_time, updated_at) \
         VALUES (1, 1, 'every_3_days', 3, '09:00', ?)",
        vec![now.clone().into()],
    ))
    .await?;

    db.execute_raw(Statement::from_sql_and_values(
        DatabaseBackend::Sqlite,
        "INSERT OR IGNORE INTO care_solution_expiry_settings \
         (id, is_active, advance_days, reminder_time, updated_at) VALUES (1, 1, 3, '09:00', ?)",
        vec![now.clone().into()],
    ))
    .await?;

    for (key, value) in DEFAULT_SETTINGS {
        db.execute_raw(Statement::from_sql_and_values(
            DatabaseBackend::Sqlite,
            "INSERT OR IGNORE INTO app_settings (key, value, updated_at) VALUES (?, ?, ?)",
            vec![key.into(), value.into(), now.clone().into()],
        ))
        .await?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use sea_orm::ConnectionTrait;

    async fn table_count(db: &DatabaseConnection) -> usize {
        db.query_all_raw(Statement::from_string(
            DatabaseBackend::Sqlite,
            "SELECT name FROM sqlite_master WHERE type = 'table'".to_owned(),
        ))
        .await
        .unwrap()
        .len()
    }

    /// 迁移 + 种子必须在全新数据库上完整执行，且可重复启动不重复插入。
    #[tokio::test]
    async fn migration_and_seed_are_idempotent() {
        let dir = std::env::temp_dir().join("moemoment_migration_test");
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let db = connect(&dir.join("test.sqlite3")).await.unwrap();

        init(&db).await.expect("首次初始化应成功");
        let first = table_count(&db).await;
        // 10 张业务表 + sqlite_sequence + seaql_migrations
        assert!(first >= 11, "表数量不足：{first}");

        init(&db).await.expect("重复初始化应幂等");
        assert_eq!(first, table_count(&db).await);

        // 内置周期必须是 6 条，且不会因重复启动而重复插入
        let cycles = db
            .query_all_raw(Statement::from_string(
                DatabaseBackend::Sqlite,
                "SELECT cycle_name FROM lens_cycles WHERE is_builtin = 1".to_owned(),
            ))
            .await
            .unwrap();
        assert_eq!(cycles.len(), 6);

        // 外键约束必须生效：插入不存在的 cycle_id 应当失败
        let bad = db
            .execute_unprepared(
                "INSERT INTO lenses (brand, name, cycle_id, status, created_at, updated_at) \
                 VALUES ('x', 'y', 9999, 'unopened', '2026-01-01', '2026-01-01')",
            )
            .await;
        assert!(bad.is_err(), "外键约束未生效");
    }
}
