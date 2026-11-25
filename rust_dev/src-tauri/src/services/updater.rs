//! 自动更新模块：与美瞳业务完全解耦。
//!
//! - Releases 来自 GitHub API，仓库信息集中在 [`UpdaterConfig`]，默认是占位值；
//! - 镜像地址必须是显式配置的白名单，未配置时镜像模式会明确报错，不臆造服务地址；
//! - 下载后可计算 SHA-256，并在 Release 附带校验文件时完成比对；
//! - 各平台只提供该平台允许的安装引导，不伪造 iOS 自动安装能力。

use futures_util::StreamExt;
use serde::Deserialize;
use sha2::{Digest, Sha256};
use tauri::{AppHandle, Emitter, Manager};
use tokio::io::AsyncWriteExt;

use crate::dto::{DownloadResultDto, UpdateAssetDto, UpdateInfoDto};
use crate::error::{AppError, AppResult};

/// GitHub 仓库占位配置：上线前必须填写（README 有清单）。
pub const GITHUB_OWNER: &str = "YOUR_GITHUB_OWNER";
pub const GITHUB_REPO: &str = "YOUR_GITHUB_REPO";

/// 可信镜像白名单。留空表示未配置镜像，此时 mirror 模式会提示用户先配置。
pub const MIRROR_BASES: &[&str] = &[];

const USER_AGENT: &str = "MoeMoment-Updater";

#[derive(Clone, Debug)]
pub struct UpdaterConfig {
    pub owner: String,
    pub repo: String,
    pub channel: String,
    pub mirror_mode: String,
}

impl UpdaterConfig {
    pub fn is_configured(&self) -> bool {
        !self.owner.starts_with("YOUR_") && !self.repo.starts_with("YOUR_")
    }
}

#[derive(Debug, Deserialize)]
struct ReleaseAsset {
    name: String,
    browser_download_url: String,
    size: u64,
    #[serde(default)]
    content_type: Option<String>,
}

#[derive(Debug, Deserialize)]
struct Release {
    tag_name: String,
    #[serde(default)]
    body: Option<String>,
    #[serde(default)]
    published_at: Option<String>,
    #[serde(default)]
    html_url: Option<String>,
    #[serde(default)]
    prerelease: bool,
    #[serde(default)]
    assets: Vec<ReleaseAsset>,
}

fn platform_asset_suffixes() -> &'static [&'static str] {
    if cfg!(target_os = "android") {
        &[".apk"]
    } else if cfg!(target_os = "ios") {
        &[] // iOS 不允许从 GitHub 下载安装包自行安装
    } else if cfg!(target_os = "windows") {
        &[".msi", ".exe"]
    } else if cfg!(target_os = "macos") {
        &[".dmg", ".app.tar.gz"]
    } else {
        &[".AppImage", ".deb", ".tar.gz"]
    }
}

pub fn install_hint() -> String {
    if cfg!(target_os = "android") {
        "下载 APK 后由系统安装程序确认安装；如提示「未知来源」，请先在系统设置中允许本应用安装应用。".to_string()
    } else if cfg!(target_os = "ios") {
        "iOS 不支持从 GitHub 下载 IPA 后自行安装，请通过 App Store / TestFlight 更新。".to_string()
    } else {
        "下载完成后打开安装包，按系统提示完成更新。".to_string()
    }
}

/// 语义化版本比较：支持 `v1.2.3`、`1.2.3-beta.1`，逐段按数字比较。
pub fn version_is_newer(candidate: &str, current: &str) -> bool {
    fn parse(value: &str) -> (Vec<u64>, bool) {
        let cleaned = value.trim().trim_start_matches(['v', 'V']);
        let (core, pre) = match cleaned.split_once('-') {
            Some((core, _pre)) => (core, true),
            None => (cleaned, false),
        };
        let numbers = core
            .split('.')
            .map(|part| {
                part.chars()
                    .take_while(|c| c.is_ascii_digit())
                    .collect::<String>()
                    .parse::<u64>()
                    .unwrap_or(0)
            })
            .collect::<Vec<_>>();
        (numbers, pre)
    }

    let (a, a_pre) = parse(candidate);
    let (b, b_pre) = parse(current);
    let len = a.len().max(b.len());
    for index in 0..len {
        let left = a.get(index).copied().unwrap_or(0);
        let right = b.get(index).copied().unwrap_or(0);
        if left != right {
            return left > right;
        }
    }
    // 主版本相同时，正式版高于预发布版
    b_pre && !a_pre
}

/// 找出 Release 中的校验文件（文件名包含 sha256 / checksums）。
fn pick_checksum_asset(assets: &[ReleaseAsset]) -> Option<&ReleaseAsset> {
    assets.iter().find(|asset| {
        let name = asset.name.to_ascii_lowercase();
        (name.contains("sha256") || name.contains("checksum")) && !name.ends_with(".apk")
    })
}

fn pick_asset(assets: &[ReleaseAsset]) -> Option<&ReleaseAsset> {
    let suffixes = platform_asset_suffixes();
    if suffixes.is_empty() {
        return None;
    }
    assets
        .iter()
        .find(|asset| {
            let name = asset.name.to_ascii_lowercase();
            suffixes.iter().any(|suffix| name.ends_with(&suffix.to_ascii_lowercase()))
        })
}

fn build_urls(base_url: &str, mode: &str) -> AppResult<Vec<(String, String)>> {
    match mode {
        "official" => Ok(vec![("official".to_string(), base_url.to_string())]),
        "mirror" => {
            if MIRROR_BASES.is_empty() {
                return Err(AppError::msg(
                    "尚未配置可信镜像地址（src-tauri/src/services/updater.rs 中的 MIRROR_BASES）",
                ));
            }
            Ok(MIRROR_BASES
                .iter()
                .map(|base| (format!("mirror:{base}"), format!("{}{}", base, base_url)))
                .collect())
        }
        _ => {
            // auto：镜像优先，失败回退官方
            let mut urls: Vec<(String, String)> = MIRROR_BASES
                .iter()
                .map(|base| (format!("mirror:{base}"), format!("{}{}", base, base_url)))
                .collect();
            urls.push(("official".to_string(), base_url.to_string()));
            Ok(urls)
        }
    }
}

async fn fetch_text(client: &reqwest::Client, url: &str) -> AppResult<String> {
    let response = client
        .get(url)
        .header("User-Agent", USER_AGENT)
        .header("Accept", "application/vnd.github+json")
        .send()
        .await?;
    if !response.status().is_success() {
        return Err(AppError::Http(format!("请求 {url} 失败：HTTP {}", response.status())));
    }
    Ok(response.text().await?)
}

pub async fn check(config: &UpdaterConfig, current_version: &str) -> AppResult<UpdateInfoDto> {
    if !config.is_configured() {
        return Ok(UpdateInfoDto {
            current_version: current_version.to_string(),
            latest_version: None,
            has_update: false,
            notes: None,
            published_at: None,
            release_url: None,
            asset: None,
            checksum: None,
            install_hint: install_hint(),
            source: None,
            // 面向用户的短提示；具体要改哪个常量写在 README 里，不往界面里塞路径
            error: Some("尚未配置更新源，暂时无法检查更新".to_string()),
        });
    }

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(20))
        .build()?;

    let endpoint = if config.channel == "stable" {
        format!(
            "https://api.github.com/repos/{}/{}/releases/latest",
            config.owner, config.repo
        )
    } else {
        format!(
            "https://api.github.com/repos/{}/{}/releases?per_page=10",
            config.owner, config.repo
        )
    };

    let urls = build_urls(&endpoint, &config.mirror_mode)?;
    let mut last_error: Option<String> = None;
    let mut payload: Option<String> = None;
    let mut used_source: Option<String> = None;

    for (label, url) in urls {
        match fetch_text(&client, &url).await {
            Ok(text) => {
                payload = Some(text);
                used_source = Some(label);
                break;
            }
            Err(err) => last_error = Some(err.to_string()),
        }
    }

    let Some(payload) = payload else {
        return Err(AppError::Http(last_error.unwrap_or_else(|| "请求 GitHub 失败".to_string())));
    };

    let release: Release = if config.channel == "stable" {
        serde_json::from_str(&payload)?
    } else {
        let list: Vec<Release> = serde_json::from_str(&payload)?;
        list.into_iter()
            .find(|item| !item.prerelease)
            .or_else(|| serde_json::from_str::<Vec<Release>>(&payload).ok().and_then(|v| v.into_iter().next()))
            .ok_or_else(|| AppError::msg("没有找到可用的 Release"))?
    };

    let latest = release.tag_name.trim().trim_start_matches(['v', 'V']).to_string();
    let to_dto = |found: &ReleaseAsset| UpdateAssetDto {
        name: found.name.clone(),
        url: found.browser_download_url.clone(),
        size: found.size,
        content_type: found.content_type.clone(),
    };
    let asset = pick_asset(&release.assets).map(to_dto);
    let checksum = pick_checksum_asset(&release.assets).map(to_dto);

    Ok(UpdateInfoDto {
        current_version: current_version.to_string(),
        has_update: version_is_newer(&latest, current_version),
        latest_version: Some(latest),
        notes: release.body,
        published_at: release.published_at,
        release_url: release.html_url,
        asset,
        checksum,
        install_hint: install_hint(),
        source: used_source,
        error: None,
    })
}

/// 读取校验文件文本（SHA256SUMS 之类），由前端解析出目标文件的哈希。
pub async fn fetch_checksum_text(url: &str) -> AppResult<String> {
    if !url.starts_with("https://") {
        return Err(AppError::msg("校验文件地址必须是 HTTPS"));
    }
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()?;
    fetch_text(&client, url).await
}

/// 下载安装包并计算 SHA-256。`expected_sha256` 存在时必须一致，否则拒绝。
pub async fn download(
    app: &AppHandle,
    url: &str,
    expected_sha256: Option<&str>,
    file_name: &str,
) -> AppResult<DownloadResultDto> {
    let safe_name = file_name
        .rsplit(['/', '\\'])
        .next()
        .unwrap_or("update.bin")
        .replace([':', '*', '?', '"', '<', '>', '|'], "_");

    let dir = app
        .path()
        .app_data_dir()
        .map_err(|err| AppError::msg(format!("无法定位应用数据目录：{err}")))?
        .join("updates");
    std::fs::create_dir_all(&dir)?;
    let target = dir.join(&safe_name);

    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(600))
        .build()?;

    let response = client.get(url).header("User-Agent", USER_AGENT).send().await?;
    if !response.status().is_success() {
        return Err(AppError::Http(format!("下载失败：HTTP {}", response.status())));
    }

    let total = response.content_length().unwrap_or(0);
    let mut file = tokio::fs::File::create(&target).await?;
    let mut hasher = Sha256::new();
    let mut downloaded: u64 = 0;
    let mut last_emit: u64 = 0;
    let mut stream = response.bytes_stream();

    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|err| AppError::Http(err.to_string()))?;
        hasher.update(&chunk);
        file.write_all(&chunk).await?;
        downloaded += chunk.len() as u64;

        if downloaded - last_emit > 512 * 1024 {
            last_emit = downloaded;
            let _ = app.emit(
                "update://progress",
                serde_json::json!({ "downloaded": downloaded, "total": total }),
            );
        }
    }
    file.flush().await?;

    let sha256 = format!("{:x}", hasher.finalize());
    let verified = match expected_sha256.map(str::trim).filter(|v| !v.is_empty()) {
        Some(expected) => {
            if !expected.eq_ignore_ascii_case(&sha256) {
                let _ = tokio::fs::remove_file(&target).await;
                return Err(AppError::msg(
                    "SHA-256 校验失败，安装包可能被篡改或下载不完整，已删除该文件",
                ));
            }
            true
        }
        None => false,
    };

    Ok(DownloadResultDto {
        path: target.to_string_lossy().replace('\\', "/"),
        bytes: downloaded,
        sha256,
        verified,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_comparison_handles_prefix_and_parts() {
        assert!(version_is_newer("1.2.4", "1.2.3"));
        assert!(version_is_newer("v2.0.0", "1.9.9"));
        assert!(!version_is_newer("1.2.3", "1.2.3"));
        assert!(!version_is_newer("1.2.2", "1.2.3"));
        assert!(version_is_newer("1.10.0", "1.9.0"));
    }

    #[test]
    fn stable_release_beats_prerelease() {
        assert!(version_is_newer("1.0.0", "1.0.0-beta.1"));
        assert!(!version_is_newer("1.0.0-beta.1", "1.0.0"));
    }

    #[test]
    fn mirror_without_configuration_is_rejected() {
        let err = build_urls("https://example.com", "mirror").unwrap_err();
        assert!(err.to_string().contains("尚未配置可信镜像地址"));
    }
}
