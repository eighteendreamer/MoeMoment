//! `lens_expiry_reminder_settings`：美瞳到期提醒设置（单例，id 固定为 1）。

use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, serde::Serialize, serde::Deserialize)]
#[sea_orm(table_name = "lens_expiry_reminder_settings")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: i32,
    pub is_active: bool,
    pub advance_days: i32,
    /// 本地时间 HH:mm
    pub reminder_time: String,
    pub updated_at: String,
}

/// 关系通过查询显式表达（外键已在迁移中约束），这里留空。
#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
