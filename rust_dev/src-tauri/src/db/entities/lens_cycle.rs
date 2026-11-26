//! `lens_cycles`：美瞳周期表（内置 + 自定义，统一用数据驱动，不硬编码周期）。

use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, serde::Serialize, serde::Deserialize)]
#[sea_orm(table_name = "lens_cycles")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub cycle_name: String,
    /// day / week / month / year
    pub cycle_unit: String,
    pub cycle_value: i32,
    pub is_builtin: bool,
    pub sort_order: i32,
    pub created_at: String,
}

/// 关系通过查询显式表达（外键已在迁移中约束），这里留空。
#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
