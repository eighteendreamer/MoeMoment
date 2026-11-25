//! 图片持久化：前端读到的二进制以 base64 传入，写入应用数据目录下的 images/。
//!
//! 数据库保存绝对路径（经过规范化），删除文件前会校验目标确实位于图片目录内，
//! 避免误删相册原图或其他记录的文件。

use std::path::{Path, PathBuf};
use std::sync::OnceLock;

use base64::{engine::general_purpose::STANDARD, Engine as _};

use crate::error::{AppError, AppResult};

static IMAGES_DIR: OnceLock<PathBuf> = OnceLock::new();

/// 应用启动时初始化图片目录（并确保存在）。
pub fn init(images_dir: PathBuf) -> AppResult<()> {
    std::fs::create_dir_all(&images_dir)?;
    let _ = IMAGES_DIR.set(images_dir);
    Ok(())
}

pub fn images_dir_global() -> AppResult<PathBuf> {
    IMAGES_DIR
        .get()
        .cloned()
        .ok_or_else(|| AppError::msg("图片目录尚未初始化"))
}

fn extension_from_mime(mime: &str) -> Option<&'static str> {
    match mime {
        "image/png" => Some("png"),
        "image/jpeg" | "image/jpg" => Some("jpg"),
        "image/webp" => Some("webp"),
        "image/gif" => Some("gif"),
        "image/heic" => Some("heic"),
        "image/bmp" => Some("bmp"),
        _ => None,
    }
}

/// 保存一张图片，返回绝对路径。
///
/// `data` 支持纯 base64 或 `data:image/png;base64,...` 形式的 Data URL。
pub fn save_base64_image(data: &str, mime_hint: Option<&str>) -> AppResult<String> {
    let dir = images_dir_global()?;

    let (mime, payload) = match data.split_once(',') {
        Some((header, payload)) if header.starts_with("data:") => {
            let mime = header
                .trim_start_matches("data:")
                .split(';')
                .next()
                .unwrap_or("image/png");
            (Some(mime.to_string()), payload)
        }
        _ => (mime_hint.map(str::to_string), data),
    };

    let extension = mime
        .as_deref()
        .and_then(extension_from_mime)
        .or_else(|| mime_hint.and_then(extension_from_mime))
        .unwrap_or("jpg");

    let bytes = STANDARD
        .decode(payload.trim())
        .map_err(|err| AppError::msg(format!("图片数据解析失败：{err}")))?;

    if bytes.is_empty() {
        return Err(AppError::msg("图片内容为空"));
    }
    if bytes.len() > 20 * 1024 * 1024 {
        return Err(AppError::msg("图片超过 20MB，请压缩后再试"));
    }

    let file_name = format!(
        "lens_{}_{}.{extension}",
        chrono::Local::now().format("%Y%m%d%H%M%S%3f"),
        std::process::id()
    );
    let path = dir.join(file_name);
    std::fs::write(&path, bytes)?;

    Ok(path.to_string_lossy().replace('\\', "/"))
}

/// 只删除确实位于图片目录内的文件；目录外路径一律忽略。
pub fn delete_files(dir: &Path, paths: &[String]) {
    let Ok(canonical_dir) = dir.canonicalize() else {
        return;
    };
    for path in paths {
        let candidate = Path::new(path);
        let Ok(canonical) = candidate.canonicalize() else {
            continue;
        };
        if canonical.starts_with(&canonical_dir) && canonical.is_file() {
            let _ = std::fs::remove_file(canonical);
        }
    }
}

pub fn delete_file(dir: &Path, path: &str) -> AppResult<()> {
    delete_files(dir, &[path.to_string()]);
    Ok(())
}
