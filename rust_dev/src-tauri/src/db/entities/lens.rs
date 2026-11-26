//! `lenses`：美瞳主表。业务日期统一存本地日历日期字符串（YYYY-MM-DD），
//! 时间戳存 RFC3339 字符串，避免 UTC 转换导致的日期偏移。

use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel, serde::Serialize, serde::Deserialize)]
#[sea_orm(table_name = "lenses")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub brand: String,
    pub name: String,
    pub cycle_id: i32,
    pub color_scheme: Option<String>,
    /// 镜片参数 JSON TEXT，键名保留原始拼写
    pub lens_specs: Option<String>,
    /// 持久化状态：unopened / opened / discarded（expired 由业务层推导）
    pub status: String,
    pub opened_at: Option<String>,
    pub package_expiry_date: Option<String>,
    pub discarded_at: Option<String>,
    pub note: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

/// 关系通过查询显式表达（外键已在迁移中约束），这里留空。
#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
