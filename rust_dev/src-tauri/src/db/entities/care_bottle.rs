//! `care_solution_bottles`：护理液信息表。

use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, serde::Serialize, serde::Deserialize)]
#[sea_orm(table_name = "care_solution_bottles")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub brand: String,
    pub name: String,
    pub opened_at: Option<String>,
    pub package_expiry_date: Option<String>,
    pub after_open_valid_days: Option<i32>,
    pub is_current: bool,
    pub note: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

/// 关系通过查询显式表达（外键已在迁移中约束），这里留空。
#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
