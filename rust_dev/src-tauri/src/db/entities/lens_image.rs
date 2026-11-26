//! `lens_images`：美瞳图片表，仅保存持久化目录内的相对路径与排序。

use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, serde::Serialize, serde::Deserialize)]
#[sea_orm(table_name = "lens_images")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub lens_id: i32,
    pub image_path: String,
    pub sort_order: i32,
    pub created_at: String,
}

/// 关系通过查询显式表达（外键已在迁移中约束），这里留空。
#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
