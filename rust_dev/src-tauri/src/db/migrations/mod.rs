//! 数据库迁移。
//!
//! 采用 SeaORM 迁移器管理版本，DDL 以 SQL 文件承载，方便审阅与对比。
//! 迁移只做增量变更，禁止通过删库重建处理升级。

use sea_orm_migration::prelude::*;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![Box::new(m20260101_000001_init::Migration)]
    }
}

pub mod m20260101_000001_init {
    use super::*;

    const INIT_SQL: &str = include_str!("../sql/001_init.sql");

    pub struct Migration;

    impl MigrationName for Migration {
        fn name(&self) -> &str {
            "m20260101_000001_init"
        }
    }

    #[async_trait::async_trait]
    impl MigrationTrait for Migration {
        async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
            let db = manager.get_connection();
            // 逐条执行：sqlx 的预处理语句只接受单条 SQL，因此按分号切分并去掉行注释，
            // 保证每个分片恰好是一条可执行语句。
            for chunk in INIT_SQL.split(';') {
                let statement = chunk
                    .lines()
                    .filter(|line| !line.trim_start().starts_with("--"))
                    .collect::<Vec<_>>()
                    .join("\n");
                let statement = statement.trim();
                if statement.is_empty() {
                    continue;
                }
                db.execute_unprepared(statement).await?;
            }
            Ok(())
        }

        async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
            let db = manager.get_connection();
            // 注意顺序：先删子表，再删父表
            for table in [
                "notification_logs",
                "app_settings",
                "care_solution_expiry_settings",
                "care_solution_bottles",
                "care_solution_change_logs",
                "care_solution_change_reminders",
                "lens_expiry_reminder_settings",
                "lens_images",
                "lenses",
                "lens_cycles",
            ] {
                db.execute_unprepared(&format!("DROP TABLE IF EXISTS {table}"))
                    .await?;
            }
            Ok(())
        }
    }
}
