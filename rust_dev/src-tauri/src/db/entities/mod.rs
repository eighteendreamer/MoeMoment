//! SeaORM 实体定义：每张表独立一个模块，避免 Entity/Column 等生成名冲突。

pub mod app_setting;
pub mod care_bottle;
pub mod care_change_log;
pub mod care_change_reminder;
pub mod care_expiry_setting;
pub mod lens;
pub mod lens_cycle;
pub mod lens_expiry_setting;
pub mod lens_image;
pub mod notification_log;
