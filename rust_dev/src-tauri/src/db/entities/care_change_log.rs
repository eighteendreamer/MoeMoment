//! `care_solution_change_logs`：护理液更换历史。

use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, serde::Serialize, serde::Deserialize)]
#[sea_orm(table_name = "care_solution_change_logs")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub reminder_id: i32,
    /// 更换发生的本地日期 YYYY-MM-DD
    pub changed_at: String,
    pub note: Option<String>,
    pub created_at: String,
}

/// 关系通过查询显式表达（外键已在迁移中约束），这里留空。
#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
