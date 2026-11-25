//! `care_solution_change_reminders`：护理液更换提醒（首期单例配置，id 固定为 1）。

use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "care_solution_change_reminders")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub id: i32,
    pub is_active: bool,
    /// daily / every_2_days / every_3_days / weekly / custom，实际计算以 interval_days 为准
    pub frequency: String,
    pub interval_days: i32,
    pub reminder_time: String,
    pub last_changed_date: Option<String>,
    pub next_changed_date: Option<String>,
    pub updated_at: String,
}

/// 关系通过查询显式表达（外键已在迁移中约束），这里留空。
#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
