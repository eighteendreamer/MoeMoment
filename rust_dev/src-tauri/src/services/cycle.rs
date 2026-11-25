//! 周期管理：内置周期不可删除/改名，被引用的周期不可删除。

use std::collections::HashMap;

use sea_orm::{ActiveModelTrait, ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, Set};

use crate::db::entities::{lens, lens_cycle};
use crate::domain::dates::{now_iso, CycleUnit};
use crate::dto::{CycleDto, CycleUpsert};
use crate::error::{AppError, AppResult};

fn validate(input: &CycleUpsert) -> AppResult<(String, CycleUnit, i32)> {
    let name = input.cycle_name.trim().to_string();
    if name.is_empty() {
        return Err(AppError::msg("请填写周期名称"));
    }
    if name.chars().count() > 20 {
        return Err(AppError::msg("周期名称不能超过 20 个字符"));
    }
    let unit = CycleUnit::parse(&input.cycle_unit)
        .ok_or_else(|| AppError::msg("周期单位只能是 day / week / month / year"))?;
    if input.cycle_value <= 0 {
        return Err(AppError::msg("周期数值必须是正整数"));
    }
    if input.cycle_value > 999 {
        return Err(AppError::msg("周期数值过大，请检查"));
    }
    Ok((name, unit, input.cycle_value))
}

async fn counts(db: &DatabaseConnection) -> AppResult<HashMap<i32, u32>> {
    let rows = lens::Entity::find().all(db).await?;
    let mut map: HashMap<i32, u32> = HashMap::new();
    for row in rows {
        *map.entry(row.cycle_id).or_default() += 1;
    }
    Ok(map)
}

fn to_dto(model: lens_cycle::Model, count: u32) -> CycleDto {
    CycleDto {
        id: model.id,
        cycle_name: model.cycle_name,
        cycle_unit: model.cycle_unit,
        cycle_value: model.cycle_value,
        is_builtin: model.is_builtin,
        sort_order: model.sort_order,
        lens_count: count,
    }
}

pub async fn list(db: &DatabaseConnection) -> AppResult<Vec<CycleDto>> {
    let counts = counts(db).await?;
    let rows = lens_cycle::Entity::find()
        .all(db)
        .await?
        .into_iter()
        .map(|row| {
            let count = counts.get(&row.id).copied().unwrap_or(0);
            to_dto(row, count)
        })
        .collect::<Vec<_>>();

    let mut rows = rows;
    rows.sort_by(|a, b| {
        a.sort_order
            .cmp(&b.sort_order)
            .then_with(|| b.is_builtin.cmp(&a.is_builtin))
            .then_with(|| a.id.cmp(&b.id))
    });
    Ok(rows)
}

pub async fn create(db: &DatabaseConnection, input: CycleUpsert) -> AppResult<CycleDto> {
    let (name, unit, value) = validate(&input)?;

    let duplicated = lens_cycle::Entity::find()
        .filter(lens_cycle::Column::CycleName.eq(name.clone()))
        .filter(lens_cycle::Column::CycleUnit.eq(unit.as_str()))
        .filter(lens_cycle::Column::CycleValue.eq(value))
        .one(db)
        .await?;
    if duplicated.is_some() {
        return Err(AppError::msg("已存在相同的周期，请直接使用"));
    }

    let sort_order = input.sort_order.unwrap_or_else(|| 100 + value);

    let inserted = lens_cycle::ActiveModel {
        cycle_name: Set(name),
        cycle_unit: Set(unit.as_str().to_string()),
        cycle_value: Set(value),
        is_builtin: Set(false),
        sort_order: Set(sort_order),
        created_at: Set(now_iso()),
        ..Default::default()
    }
    .insert(db)
    .await?;

    Ok(to_dto(inserted, 0))
}

pub async fn update(db: &DatabaseConnection, id: i32, input: CycleUpsert) -> AppResult<CycleDto> {
    let existing = lens_cycle::Entity::find_by_id(id)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("周期不存在"))?;

    if existing.is_builtin {
        return Err(AppError::msg("内置周期不支持修改，请新建自定义周期"));
    }

    let (name, unit, value) = validate(&input)?;

    let duplicated = lens_cycle::Entity::find()
        .filter(lens_cycle::Column::CycleName.eq(name.clone()))
        .filter(lens_cycle::Column::CycleUnit.eq(unit.as_str()))
        .filter(lens_cycle::Column::CycleValue.eq(value))
        .filter(lens_cycle::Column::Id.ne(id))
        .one(db)
        .await?;
    if duplicated.is_some() {
        return Err(AppError::msg("已存在相同的周期"));
    }

    let count = counts(db).await?.get(&id).copied().unwrap_or(0);

    let mut active: lens_cycle::ActiveModel = existing.into();
    active.cycle_name = Set(name);
    active.cycle_unit = Set(unit.as_str().to_string());
    active.cycle_value = Set(value);
    if let Some(order) = input.sort_order {
        active.sort_order = Set(order);
    }
    let updated = active.update(db).await?;

    Ok(to_dto(updated, count))
}

pub async fn delete(db: &DatabaseConnection, id: i32) -> AppResult<()> {
    let existing = lens_cycle::Entity::find_by_id(id)
        .one(db)
        .await?
        .ok_or_else(|| AppError::msg("周期不存在"))?;

    if existing.is_builtin {
        return Err(AppError::msg("内置周期不能删除"));
    }

    let count = counts(db).await?.get(&id).copied().unwrap_or(0);
    if count > 0 {
        return Err(AppError::msg(format!(
            "该周期已被 {count} 副美瞳使用，请先调整这些美瞳的周期"
        )));
    }

    lens_cycle::Entity::delete_by_id(id).exec(db).await?;
    Ok(())
}
