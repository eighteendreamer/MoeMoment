//! 美瞳业务：查询、增删改、开封、丢弃、统计。
//!
//! 所有到期/状态都由 [`crate::domain::lens`] 的纯函数计算，数据库只存事实
//! （状态、开封日、包装有效期），不存派生的「已过期」或统计数字。

use std::collections::HashMap;

use chrono::NaiveDate;
use sea_orm::{
    ActiveModelTrait, ColumnTrait, Condition, DatabaseConnection, EntityTrait, QueryFilter,
    QueryOrder, QuerySelect, Set, TransactionTrait,
};

use crate::db::entities::{lens, lens_cycle, lens_image};
use crate::domain::dates::{fmt_date, now_iso, today};
use crate::domain::lens::{
    compute_expiry, derive_state, is_expiring_soon, LensState, STATUS_DISCARDED, STATUS_OPENED,
    STATUS_UNOPENED,
};
use crate::dto::{HomeOverview, HomeStats, LensDto, LensFilter, LensImageDto, LensSpecs, LensUpsert};
use crate::error::{AppError, AppResult};
use crate::services::parse_required_date;

/// 默认提前提醒天数（读取设置失败时的兜底，与需求一致）。
pub const DEFAULT_ADVANCE_DAYS: i32 = 3;

pub struct LensContext {
    pub cycles: HashMap<i32, lens_cycle::Model>,
    pub images: HashMap<i32, Vec<lens_image::Model>>,
    pub today: NaiveDate,
    pub advance_days: i32,
}

impl LensContext {
    pub async fn load(db: &DatabaseConnection, advance_days: i32) -> AppResult<Self> {
        let cycles = lens_cycle::Entity::find().all(db).await?;
        let images = lens_image::Entity::find()
            .order_by_asc(lens_image::Column::SortOrder)
            .order_by_asc(lens_image::Column::Id)
            .all(db)
            .await?;

        let mut image_map: HashMap<i32, Vec<lens_image::Model>> = HashMap::new();
        for image in images {
            image_map.entry(image.lens_id).or_default().push(image);
        }

        Ok(Self {
            cycles: cycles.into_iter().map(|c| (c.id, c)).collect(),
            images: image_map,
            today: today(),
            advance_days,
        })
    }

    pub fn to_dto(&self, model: lens::Model) -> AppResult<LensDto> {
        let cycle = self
            .cycles
            .get(&model.cycle_id)
            .ok_or_else(|| AppError::msg("美瞳关联的周期已不存在"))?;

        let unit = crate::domain::dates::CycleUnit::parse(&cycle.cycle_unit)
            .ok_or_else(|| AppError::msg("周期单位数据异常"))?;

        let opened_at = crate::domain::dates::parse_opt_date(model.opened_at.as_deref());
        let package_expiry = crate::domain::dates::parse_opt_date(model.package_expiry_date.as_deref());

        let expiry = compute_expiry(
            &model.status,
            opened_at,
            Some((unit, cycle.cycle_value)),
            package_expiry,
            self.today,
        );

        let state = derive_state(&model.status, expiry.expiry_date, self.today);

        let images = self
            .images
            .get(&model.id)
            .map(|rows| {
                rows.iter()
                    .map(|row| LensImageDto {
                        id: row.id,
                        path: row.image_path.clone(),
                        sort_order: row.sort_order,
                    })
                    .collect()
            })
            .unwrap_or_default();

        Ok(LensDto {
            id: model.id,
            brand: model.brand,
            name: model.name,
            cycle_id: model.cycle_id,
            cycle_name: cycle.cycle_name.clone(),
            cycle_unit: cycle.cycle_unit.clone(),
            cycle_value: cycle.cycle_value,
            color_scheme: model.color_scheme,
            lens_specs: LensSpecs::parse(model.lens_specs.as_deref()),
            status: model.status,
            state: state.as_str().to_string(),
            expiry_date: expiry.expiry_date.map(fmt_date),
            expiry_source: expiry.source.as_str().to_string(),
            days_remaining: expiry.days_remaining,
            is_expiring_soon: is_expiring_soon(expiry.expiry_date, self.today, self.advance_days),
            opened_at: model.opened_at,
            package_expiry_date: model.package_expiry_date,
            discarded_at: model.discarded_at,
            note: model.note,
            images,
            created_at: model.created_at,
            updated_at: model.updated_at,
        })
    }
}

/// 读取美瞳到期提醒的开关与提前天数。
pub async fn reminder_config(db: &DatabaseConnection) -> AppResult<(bool, i32)> {
    use crate::db::entities::lens_expiry_setting;
    let setting = lens_expiry_setting::Entity::find_by_id(1).one(db).await?;
    Ok(match setting {
        Some(row) => (row.is_active, row.advance_days),
        None => (true, DEFAULT_ADVANCE_DAYS),
    })
}

/// 去重后的颜色方案列表，供筛选弹层使用。
pub async fn colors(db: &DatabaseConnection) -> AppResult<Vec<String>> {
    let rows = lens::Entity::find()
        .select_only()
        .column(lens::Column::ColorScheme)
        .filter(lens::Column::ColorScheme.is_not_null())
        .distinct()
        .into_tuple::<Option<String>>()
        .all(db)
        .await?;

    let mut result: Vec<String> = rows
        .into_iter()
        .flatten()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
        .collect();
    result.sort_by(|a, b| a.cmp(b));
    result.dedup();
    Ok(result)
}

/// 列表查询：关键词、周期、颜色方案在 SQL 层过滤，派生状态在内存中过滤。
pub async fn list(db: &DatabaseConnection, filter: LensFilter) -> AppResult<Vec<LensDto>> {
    let (_, advance_days) = reminder_config(db).await?;
    let ctx = LensContext::load(db, advance_days).await?;

    let mut query = lens::Entity::find();

    if let Some(keyword) = filter
        .keyword
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
    {
        query = query.filter(
            Condition::any()
                .add(lens::Column::Brand.contains(keyword))
                .add(lens::Column::Name.contains(keyword))
                .add(lens::Column::ColorScheme.contains(keyword)),
        );
    }

    if let Some(cycle_id) = filter.cycle_id {
        query = query.filter(lens::Column::CycleId.eq(cycle_id));
    }

    if let Some(color) = filter
        .color_scheme
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
    {
        query = query.filter(lens::Column::ColorScheme.eq(color));
    }

    let rows = query
        .order_by_desc(lens::Column::UpdatedAt)
        .order_by_desc(lens::Column::Id)
        .all(db)
        .await?;

    let wanted_state = filter.state.as_deref().unwrap_or("all");
    let mut result = Vec::with_capacity(rows.len());
    for row in rows {
        let dto = ctx.to_dto(row)?;
        if wanted_state == "all" || wanted_state.is_empty() || dto.state == wanted_state {
            result.push(dto);
        }
    }
    Ok(result)
}

pub async fn get(db: &DatabaseConnection, lens_id: i32) -> AppResult<LensDto> {
    let (_, advance_days) = reminder_config(db).await?;
    let ctx = LensContext::load(db, advance_days).await?;
    let model = lens::Entity::find_by_id(lens_id)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("美瞳记录不存在或已被删除"))?;
    ctx.to_dto(model)
}

fn validate_upsert(payload: &LensUpsert) -> AppResult<()> {
    if payload.name.trim().is_empty() {
        return Err(AppError::msg("请填写美瞳名称"));
    }
    if payload.brand.trim().is_empty() {
        return Err(AppError::msg("请填写品牌"));
    }
    if payload.cycle_id <= 0 {
        return Err(AppError::msg("请选择使用周期"));
    }
    Ok(())
}

/// 用图片表整体替换某副美瞳的图片顺序（在事务内执行）。
async fn replace_images(
    db: &impl sea_orm::ConnectionTrait,
    lens_id: i32,
    images: &[String],
) -> AppResult<Vec<String>> {
    let existing = lens_image::Entity::find()
        .filter(lens_image::Column::LensId.eq(lens_id))
        .all(db)
        .await?;

    // 记录将要被移除的路径，交由调用方在事务提交后清理文件
    let removed: Vec<String> = existing
        .iter()
        .filter(|row| !images.iter().any(|path| path == &row.image_path))
        .map(|row| row.image_path.clone())
        .collect();

    lens_image::Entity::delete_many()
        .filter(lens_image::Column::LensId.eq(lens_id))
        .exec(db)
        .await?;

    let now = now_iso();
    for (index, path) in images.iter().enumerate() {
        lens_image::ActiveModel {
            lens_id: Set(lens_id),
            image_path: Set(path.clone()),
            sort_order: Set(index as i32),
            created_at: Set(now.clone()),
            ..Default::default()
        }
        .insert(db)
        .await?;
    }

    Ok(removed)
}

pub async fn create(db: &DatabaseConnection, payload: LensUpsert) -> AppResult<LensDto> {
    validate_upsert(&payload)?;
    let package_expiry = parse_required_date(payload.package_expiry_date.clone(), "包装有效期")?;

    let cycle_exists = lens_cycle::Entity::find_by_id(payload.cycle_id).one(db).await?;
    if cycle_exists.is_none() {
        return Err(AppError::msg("所选周期不存在，请刷新后重试"));
    }

    let txn = db.begin().await?;
    let now = now_iso();

    let inserted = lens::ActiveModel {
        brand: Set(payload.brand.trim().to_string()),
        name: Set(payload.name.trim().to_string()),
        cycle_id: Set(payload.cycle_id),
        color_scheme: Set(normalize_optional(payload.color_scheme.clone())),
        lens_specs: Set(payload.lens_specs.as_ref().and_then(|s| s.to_storage())),
        status: Set(STATUS_UNOPENED.to_string()),
        opened_at: Set(None),
        package_expiry_date: Set(package_expiry.map(fmt_date)),
        discarded_at: Set(None),
        note: Set(normalize_optional(payload.note.clone())),
        created_at: Set(now.clone()),
        updated_at: Set(now.clone()),
        ..Default::default()
    }
    .insert(&txn)
    .await?;

    replace_images(&txn, inserted.id, &payload.images).await?;
    txn.commit().await?;

    get(db, inserted.id).await
}

pub async fn update(db: &DatabaseConnection, lens_id: i32, payload: LensUpsert) -> AppResult<LensDto> {
    validate_upsert(&payload)?;
    let package_expiry = parse_required_date(payload.package_expiry_date.clone(), "包装有效期")?;

    let existing = lens::Entity::find_by_id(lens_id)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("美瞳记录不存在或已被删除"))?;

    let cycle_exists = lens_cycle::Entity::find_by_id(payload.cycle_id).one(db).await?;
    if cycle_exists.is_none() {
        return Err(AppError::msg("所选周期不存在，请刷新后重试"));
    }

    let txn = db.begin().await?;
    let mut active: lens::ActiveModel = existing.into();
    active.brand = Set(payload.brand.trim().to_string());
    active.name = Set(payload.name.trim().to_string());
    active.cycle_id = Set(payload.cycle_id);
    active.color_scheme = Set(normalize_optional(payload.color_scheme.clone()));
    active.lens_specs = Set(payload.lens_specs.as_ref().and_then(|s| s.to_storage()));
    active.package_expiry_date = Set(package_expiry.map(fmt_date));
    active.note = Set(normalize_optional(payload.note.clone()));
    active.updated_at = Set(now_iso());
    active.update(&txn).await?;

    let removed = replace_images(&txn, lens_id, &payload.images).await?;
    txn.commit().await?;

    // 事务提交成功后再清理文件，失败也不影响数据一致性
    if !removed.is_empty() {
        if let Ok(dir) = crate::services::media::images_dir_global() {
            crate::services::media::delete_files(&dir, &removed);
        }
    }

    get(db, lens_id).await
}

/// 删除美瞳：先取图片路径，提交删除后再清理文件。
pub async fn delete(db: &DatabaseConnection, lens_id: i32) -> AppResult<()> {
    let images = lens_image::Entity::find()
        .filter(lens_image::Column::LensId.eq(lens_id))
        .all(db)
        .await?;

    let result = lens::Entity::delete_by_id(lens_id).exec(db).await?;
    if result.rows_affected == 0 {
        return Err(AppError::msg("美瞳记录不存在或已被删除"));
    }

    if let Ok(dir) = crate::services::media::images_dir_global() {
        let paths: Vec<String> = images.into_iter().map(|row| row.image_path).collect();
        crate::services::media::delete_files(&dir, &paths);
    }
    Ok(())
}

/// 标记开封：保存用户确认的日期、切换状态、由周期重算到期日（DTO 中返回）。
pub async fn open(db: &DatabaseConnection, lens_id: i32, opened_at: Option<String>) -> AppResult<LensDto> {
    let existing = lens::Entity::find_by_id(lens_id)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("美瞳记录不存在或已被删除"))?;

    if existing.status == STATUS_DISCARDED {
        return Err(AppError::msg("已丢弃的美瞳不能标记开封"));
    }

    let date = match parse_required_date(opened_at, "开封日期")? {
        Some(date) => date,
        None => today(),
    };
    if date > today() {
        return Err(AppError::msg("开封日期不能晚于今天"));
    }
    if let Some(package_expiry) = crate::domain::dates::parse_opt_date(existing.package_expiry_date.as_deref())
        && date > package_expiry
    {
        return Err(AppError::msg("开封日期已超过包装有效期，请检查日期"));
    }

    let mut active: lens::ActiveModel = existing.into();
    active.opened_at = Set(Some(fmt_date(date)));
    active.status = Set(STATUS_OPENED.to_string());
    active.updated_at = Set(now_iso());
    active.update(db).await?;

    get(db, lens_id).await
}

pub async fn discard(db: &DatabaseConnection, lens_id: i32) -> AppResult<LensDto> {
    let existing = lens::Entity::find_by_id(lens_id)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("美瞳记录不存在或已被删除"))?;

    let mut active: lens::ActiveModel = existing.into();
    active.status = Set(STATUS_DISCARDED.to_string());
    active.discarded_at = Set(Some(fmt_date(today())));
    active.updated_at = Set(now_iso());
    active.update(db).await?;

    get(db, lens_id).await
}

/// 恢复到未开封（丢弃操作的反悔入口）。
pub async fn restore_unopened(db: &DatabaseConnection, lens_id: i32) -> AppResult<LensDto> {
    let existing = lens::Entity::find_by_id(lens_id)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("美瞳记录不存在或已被删除"))?;

    let mut active: lens::ActiveModel = existing.into();
    active.status = Set(STATUS_UNOPENED.to_string());
    active.opened_at = Set(None);
    active.discarded_at = Set(None);
    active.updated_at = Set(now_iso());
    active.update(db).await?;

    get(db, lens_id).await
}

/// 首页数据：即将到期、已过期、最近添加、统计。
pub async fn home_overview(db: &DatabaseConnection) -> AppResult<HomeOverview> {
    let (enabled, advance_days) = reminder_config(db).await?;
    let ctx = LensContext::load(db, advance_days).await?;

    let rows = lens::Entity::find()
        .order_by_desc(lens::Column::UpdatedAt)
        .order_by_desc(lens::Column::Id)
        .all(db)
        .await?;

    let mut expiring = Vec::new();
    let mut expired = Vec::new();
    let mut recent = Vec::new();
    let mut stats = HomeStats::default();

    for row in rows {
        let dto = ctx.to_dto(row)?;

        match dto.state.as_str() {
            "in_use" => stats.in_use += 1,
            "unopened" => stats.unopened += 1,
            "expired" => stats.expired += 1,
            "discarded" => stats.discarded += 1,
            _ => {}
        }

        if dto.state != LensState::Discarded.as_str() {
            stats.total += 1;
            if dto.state == "expired" {
                expired.push(dto.clone());
            } else if dto.is_expiring_soon {
                expiring.push(dto.clone());
            }
            if recent.len() < 6 {
                recent.push(dto);
            }
        }
    }

    // 即将到期按到期日升序；已过期按到期日降序（越近越靠前）
    expiring.sort_by(|a, b| a.expiry_date.cmp(&b.expiry_date));
    expired.sort_by(|a, b| b.expiry_date.cmp(&a.expiry_date));

    Ok(HomeOverview {
        expiring,
        expired,
        recent,
        stats,
        advance_days,
        lens_reminder_enabled: enabled,
    })
}

/// 到期列表：既包含即将到期，也包含已经过期的记录。
pub async fn expiring_list(db: &DatabaseConnection) -> AppResult<Vec<LensDto>> {
    let (_, advance_days) = reminder_config(db).await?;
    let ctx = LensContext::load(db, advance_days).await?;
    let rows = lens::Entity::find().all(db).await?;

    let mut result = Vec::new();
    for row in rows {
        let dto = ctx.to_dto(row)?;
        if dto.state == "expired" || dto.is_expiring_soon {
            result.push(dto);
        }
    }
    result.sort_by(|a, b| a.expiry_date.cmp(&b.expiry_date));
    Ok(result)
}

/// 可选字段的空串归一为 NULL，避免出现「空字符串」与 NULL 两种空值。
fn normalize_optional(value: Option<String>) -> Option<String> {
    value.and_then(|raw| {
        let trimmed = raw.trim().to_string();
        if trimmed.is_empty() { None } else { Some(trimmed) }
    })
}

/// 供通知服务复用：所有未丢弃美瞳的 DTO。
pub async fn all_active(db: &DatabaseConnection, advance_days: i32) -> AppResult<Vec<LensDto>> {
    let ctx = LensContext::load(db, advance_days).await?;
    let rows = lens::Entity::find()
        .filter(lens::Column::Status.ne(STATUS_DISCARDED))
        .order_by_asc(lens::Column::PackageExpiryDate)
        .all(db)
        .await?;
    rows.into_iter().map(|row| ctx.to_dto(row)).collect()
}
