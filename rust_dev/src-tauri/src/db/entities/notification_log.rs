//! `notification_logs`：通知计划与发送记录，`notification_key` 唯一用于去重。

use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "notification_logs")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub notification_key: String,
    /// lens_expiry / care_change / care_expiry
    pub target_type: String,
    pub target_id: Option<i32>,
    pub scheduled_date: String,
    pub sent_at: Option<String>,
    /// scheduled / sent / failed / cancelled
    pub status: String,
    pub title: String,
    pub body: String,
}

/// 关系通过查询显式表达（外键已在迁移中约束），这里留空。
#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
