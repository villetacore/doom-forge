use std::fs;
use std::io::Write;
use std::path::Path;

use serde::{Deserialize, Serialize};

use crate::error::{AppError, AppResult};

/// A package entry in a DoomForge registry. The registry is a JSON document
/// (hosted anywhere, or local) of the shape `{ "packages": [PackageEntry...] }`.
///
/// This is deliberately a generic registry rather than scraping Doomworld/ModDB
/// HTML: those sites have no stable public API and their markup changes often,
/// so a maintained registry index is the robust integration point. A scraper
/// adapter can later populate such an index.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PackageEntry {
    pub id: String,
    pub name: String,
    #[serde(default)]
    pub description: String,
    #[serde(default)]
    pub version: String,
    /// Direct download URL of the pk3/wad/zip.
    pub url: String,
    #[serde(default)]
    pub tags: Vec<String>,
    #[serde(default)]
    pub homepage: Option<String>,
}

#[derive(Debug, Deserialize)]
struct Registry {
    #[serde(default)]
    packages: Vec<PackageEntry>,
}

fn client() -> AppResult<reqwest::blocking::Client> {
    reqwest::blocking::Client::builder()
        .user_agent("DoomForge/0.1")
        .timeout(std::time::Duration::from_secs(60))
        .build()
        .map_err(|e| AppError::msg(e.to_string()))
}

/// Fetch and parse a registry from a URL or a local file path.
pub fn fetch_registry(source: &str) -> AppResult<Vec<PackageEntry>> {
    let text = if source.starts_with("http://") || source.starts_with("https://") {
        client()?
            .get(source)
            .send()
            .map_err(|e| AppError::msg(e.to_string()))?
            .text()
            .map_err(|e| AppError::msg(e.to_string()))?
    } else {
        fs::read_to_string(source)?
    };
    let reg: Registry =
        serde_json::from_str(&text).map_err(|_| AppError::msg("Invalid registry JSON"))?;
    Ok(reg.packages)
}

/// Search a registry for packages matching `query` (name/tags/description).
pub fn search_registry(source: &str, query: &str) -> AppResult<Vec<PackageEntry>> {
    let q = query.to_lowercase();
    let mut pkgs = fetch_registry(source)?;
    pkgs.retain(|p| {
        p.name.to_lowercase().contains(&q)
            || p.id.to_lowercase().contains(&q)
            || p.description.to_lowercase().contains(&q)
            || p.tags.iter().any(|t| t.to_lowercase().contains(&q))
    });
    Ok(pkgs)
}

/// Download a file from a direct URL into `dest_dir`. Returns the saved path.
/// Powers both "Import by URL" and one-click install from a registry entry.
pub fn download_to(url: &str, dest_dir: &str) -> AppResult<String> {
    let dir = Path::new(dest_dir);
    fs::create_dir_all(dir)?;

    let file_name = url
        .split('/')
        .last()
        .filter(|s| !s.is_empty())
        .unwrap_or("download.pk3")
        .split('?')
        .next()
        .unwrap_or("download.pk3")
        .to_string();
    let dest = dir.join(&file_name);

    let resp = client()?
        .get(url)
        .send()
        .map_err(|e| AppError::msg(e.to_string()))?;
    if !resp.status().is_success() {
        return Err(AppError::msg(format!("HTTP {}", resp.status())));
    }
    let mut out = fs::File::create(&dest)?;
    let bytes = resp
        .bytes()
        .map_err(|e| AppError::msg(e.to_string()))?;
    out.write_all(&bytes)?;
    Ok(dest.to_string_lossy().to_string())
}

/// Install a package by id from a registry into the mods dir.
pub fn install_package(source: &str, id: &str, mods_dir: &str) -> AppResult<String> {
    let pkgs = fetch_registry(source)?;
    let pkg = pkgs
        .into_iter()
        .find(|p| p.id == id)
        .ok_or_else(|| AppError::msg(format!("Package '{id}' not found in registry")))?;
    download_mod(&pkg.url, mods_dir)
}

// ---- Raw byte fetch --------------------------------------------------------

fn fetch_bytes(url: &str) -> AppResult<Vec<u8>> {
    let resp = client()?
        .get(url)
        .send()
        .map_err(|e| AppError::msg(e.to_string()))?;
    if !resp.status().is_success() {
        return Err(AppError::msg(format!("HTTP {} for {url}", resp.status())));
    }
    Ok(resp
        .bytes()
        .map_err(|e| AppError::msg(e.to_string()))?
        .to_vec())
}

const MOD_EXTS: &[&str] = &["pk3", "pk7", "wad", "pke", "ipk3", "deh", "bex"];

/// Download a mod from a URL into `mods_dir`. If the download is a ZIP, the
/// playable mod files inside it are extracted (idgames archives are zipped);
/// otherwise the file is saved as-is. Returns a human summary of what landed.
pub fn download_mod(url: &str, mods_dir: &str) -> AppResult<String> {
    let dir = Path::new(mods_dir);
    fs::create_dir_all(dir)?;
    let bytes = fetch_bytes(url)?;

    let looks_zip = bytes.starts_with(b"PK\x03\x04");
    if looks_zip {
        let extracted = extract_mod_files(&bytes, dir)?;
        if !extracted.is_empty() {
            return Ok(format!("Extracted: {}", extracted.join(", ")));
        }
        // Zip without recognised mod files — keep the archive itself.
    }

    let file_name = url
        .rsplit('/')
        .next()
        .and_then(|s| s.split('?').next())
        .filter(|s| !s.is_empty())
        .unwrap_or("download.pk3")
        .to_string();
    let dest = dir.join(&file_name);
    fs::write(&dest, &bytes)?;
    Ok(format!("Saved {file_name}"))
}

/// Extract entries with a known mod extension from a zip held in memory.
fn extract_mod_files(bytes: &[u8], dest: &Path) -> AppResult<Vec<String>> {
    let mut zip = zip::ZipArchive::new(std::io::Cursor::new(bytes))?;
    let mut out = Vec::new();
    for i in 0..zip.len() {
        let mut entry = zip.by_index(i)?;
        if !entry.is_file() {
            continue;
        }
        let base = entry
            .name()
            .rsplit(['/', '\\'])
            .next()
            .unwrap_or("")
            .to_string();
        let ext = base.rsplit('.').next().unwrap_or("").to_lowercase();
        if !MOD_EXTS.contains(&ext.as_str()) {
            continue;
        }
        let target = dest.join(&base);
        let mut f = fs::File::create(&target)?;
        std::io::copy(&mut entry, &mut f)?;
        out.push(base);
    }
    Ok(out)
}

// ---- GitHub release downloads (GZDoom, Freedoom) ---------------------------

/// List `(asset_name, download_url)` for a repo's latest GitHub release.
fn github_latest_assets(repo: &str) -> AppResult<Vec<(String, String)>> {
    let url = format!("https://api.github.com/repos/{repo}/releases/latest");
    let v: serde_json::Value = client()?
        .get(&url)
        .header("Accept", "application/vnd.github+json")
        .send()
        .map_err(|e| AppError::msg(e.to_string()))?
        .json()
        .map_err(|e| AppError::msg(e.to_string()))?;
    let assets = v["assets"]
        .as_array()
        .ok_or_else(|| AppError::msg("No assets in GitHub release"))?
        .iter()
        .filter_map(|a| {
            Some((
                a["name"].as_str()?.to_string(),
                a["browser_download_url"].as_str()?.to_string(),
            ))
        })
        .collect();
    Ok(assets)
}

/// Download and install the Freedoom IWADs (freedoom1.wad / freedoom2.wad)
/// into `iwad_dir`. Cross-platform — Freedoom ships only data WADs.
pub fn install_freedoom(iwad_dir: &str) -> AppResult<Vec<String>> {
    let assets = github_latest_assets("freedoom/freedoom")?;
    // The main release zip is named like "freedoom-0.13.0.zip" (not the phase1/2
    // standalone or source archives).
    let (_, url) = assets
        .iter()
        .find(|(n, _)| {
            let l = n.to_lowercase();
            l.starts_with("freedoom-") && l.ends_with(".zip") && !l.contains("src")
        })
        .ok_or_else(|| AppError::msg("Could not find the Freedoom release zip"))?;

    let dir = Path::new(iwad_dir);
    fs::create_dir_all(dir)?;
    let bytes = fetch_bytes(url)?;

    let mut zip = zip::ZipArchive::new(std::io::Cursor::new(bytes))?;
    let mut saved = Vec::new();
    for i in 0..zip.len() {
        let mut entry = zip.by_index(i)?;
        let base = entry.name().rsplit(['/', '\\']).next().unwrap_or("").to_lowercase();
        if base == "freedoom1.wad" || base == "freedoom2.wad" {
            let target = dir.join(&base);
            let mut f = fs::File::create(&target)?;
            std::io::copy(&mut entry, &mut f)?;
            saved.push(target.to_string_lossy().to_string());
        }
    }
    if saved.is_empty() {
        return Err(AppError::msg("Freedoom WADs not found inside the release zip"));
    }
    Ok(saved)
}

/// Download the latest GZDoom for the current OS into `dest_dir` and return the
/// path to the extracted folder. GZDoom publishes Windows and macOS binaries;
/// Linux has no official binary asset (install via flatpak/distro instead).
pub fn install_gzdoom(dest_dir: &str) -> AppResult<String> {
    let assets = github_latest_assets("ZDoom/gzdoom")?;
    fs::create_dir_all(dest_dir)?;

    // Windows / macOS: a .zip we can extract straight to a runnable folder.
    if cfg!(target_os = "windows") || cfg!(target_os = "macos") {
        let want = if cfg!(target_os = "windows") { "windows" } else { "macos" };
        let (name, url) = assets
            .iter()
            .find(|(n, _)| {
                let l = n.to_lowercase();
                l.contains(want) && l.ends_with(".zip") && !l.contains("pdb")
            })
            .ok_or_else(|| AppError::msg("Could not find a GZDoom binary asset"))?;
        let dir = Path::new(dest_dir).join(name.trim_end_matches(".zip"));
        fs::create_dir_all(&dir)?;
        let bytes = fetch_bytes(url)?;
        zip::ZipArchive::new(std::io::Cursor::new(bytes))?.extract(&dir)?;
        return Ok(dir.to_string_lossy().to_string());
    }

    // Linux: GZDoom ships a .deb. We can download it, but installing needs root,
    // so we save it and tell the user how to install (no silent sudo).
    let (name, url) = assets
        .iter()
        .find(|(n, _)| n.to_lowercase().ends_with("amd64.deb"))
        .ok_or_else(|| {
            AppError::msg(
                "No Linux binary in the GZDoom release. Install via flatpak \
                 (org.zdoom.GZDoom) or your distro, then use “Detect on PATH”.",
            )
        })?;
    let dest = Path::new(dest_dir).join(name);
    fs::write(&dest, fetch_bytes(url)?)?;
    Ok(format!(
        "Downloaded {name}. Install it with:  sudo apt install {}",
        dest.display()
    ))
}

// ---- idgames (Doomworld) archive API ---------------------------------------

/// A reliable public mirror for downloading idgames files.
const IDGAMES_MIRROR: &str = "https://www.quaddicted.com/files/idgames/";

/// Search the Doomworld idgames archive via its official JSON API.
/// This is the legitimate, stable mod source (unlike scraping ModDB, which has
/// no public download API).
pub fn idgames_search(query: &str) -> AppResult<Vec<PackageEntry>> {
    let url = format!(
        "https://www.doomworld.com/idgames/api/api.php?out=json&action=search&type=title&sort=rating&query={}",
        urlencode(query)
    );
    let text = client()?
        .get(&url)
        .send()
        .map_err(|e| AppError::msg(e.to_string()))?
        .text()
        .map_err(|e| AppError::msg(e.to_string()))?;
    if text.trim_start().starts_with('<') {
        return Err(AppError::msg(
            "The Doomworld idgames API is currently behind a Cloudflare challenge \
             and can't be queried directly. Use “Import by URL” with a direct file \
             link instead.",
        ));
    }
    let v: serde_json::Value =
        serde_json::from_str(&text).map_err(|e| AppError::msg(e.to_string()))?;

    if let Some(w) = v["warning"]["type"].as_str() {
        if w == "No results found." || v["content"].is_null() {
            return Ok(Vec::new());
        }
    }

    // `content.file` is an array for many results, or a single object for one.
    let files: Vec<serde_json::Value> = match &v["content"]["file"] {
        serde_json::Value::Array(a) => a.clone(),
        serde_json::Value::Object(_) => vec![v["content"]["file"].clone()],
        _ => return Ok(Vec::new()),
    };

    let pkgs = files
        .into_iter()
        .filter_map(|f| {
            let dir = f["dir"].as_str()?.to_string();
            let filename = f["filename"].as_str()?.to_string();
            Some(PackageEntry {
                id: format!("{dir}{filename}"),
                name: f["title"].as_str().unwrap_or(&filename).to_string(),
                description: format!(
                    "by {} · ★ {}",
                    f["author"].as_str().unwrap_or("unknown"),
                    f["rating"].as_f64().unwrap_or(0.0)
                ),
                version: String::new(),
                url: format!("{IDGAMES_MIRROR}{dir}{filename}"),
                tags: Vec::new(),
                homepage: f["url"].as_str().map(|s| s.to_string()),
            })
        })
        .collect();
    Ok(pkgs)
}

// ---- Built-in curated catalog ----------------------------------------------

/// A small, hand-checked catalog of free GZDoom mods hosted on GitHub. Each
/// entry's `url` uses the `github:owner/repo` scheme; the latest release asset
/// is resolved at install time so the links never go stale.
pub fn builtin_catalog() -> Vec<PackageEntry> {
    let e = |id: &str, name: &str, desc: &str, repo: &str, tags: &[&str]| PackageEntry {
        id: id.into(),
        name: name.into(),
        description: desc.into(),
        version: String::new(),
        url: format!("github:{repo}"),
        tags: tags.iter().map(|s| s.to_string()).collect(),
        homepage: Some(format!("https://github.com/{repo}")),
    };
    vec![
        e(
            "beautiful-doom",
            "Beautiful Doom",
            "Enhanced animations, gibs and effects — vanilla-compatible gameplay polish.",
            "jekyllgrim/Beautiful-Doom",
            &["gameplay", "visuals"],
        ),
        e(
            "gearbox",
            "Gearbox",
            "A fast weapon and inventory selection wheel/menu.",
            "mmaulwurff/gearbox",
            &["ui", "gameplay"],
        ),
        e(
            "target-spy",
            "Target Spy",
            "Shows the name and health bar of whatever you're aiming at.",
            "mmaulwurff/target-spy",
            &["ui", "hud"],
        ),
        e(
            "precise-crosshair",
            "Precise Crosshair",
            "A pixel-accurate crosshair that follows actual autoaim.",
            "mmaulwurff/precise-crosshair",
            &["ui", "hud"],
        ),
    ]
}

/// Resolve a catalog/entry URL (possibly `github:owner/repo`) to a direct
/// download URL, then download+extract it into `mods_dir`.
pub fn install_catalog(url: &str, mods_dir: &str) -> AppResult<String> {
    let direct = resolve_url(url)?;
    download_mod(&direct, mods_dir)
}

/// Resolve `github:owner/repo` to the best mod asset of its latest release.
/// Plain http(s) URLs are returned unchanged.
fn resolve_url(url: &str) -> AppResult<String> {
    let Some(repo) = url.strip_prefix("github:") else {
        return Ok(url.to_string());
    };
    let assets = github_latest_assets(repo)?;
    let pick = assets
        .iter()
        .find(|(n, _)| n.to_lowercase().ends_with(".pk3") && !n.to_lowercase().contains("lzdoom"))
        .or_else(|| {
            assets.iter().find(|(n, _)| {
                let l = n.to_lowercase();
                l.ends_with(".wad") || l.ends_with(".pk7") || l.ends_with(".zip")
            })
        })
        .ok_or_else(|| AppError::msg(format!("No downloadable asset for {repo}")))?;
    Ok(pick.1.clone())
}

/// Minimal percent-encoding for query strings.
fn urlencode(s: &str) -> String {
    s.bytes()
        .map(|b| match b {
            b'a'..=b'z' | b'A'..=b'Z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                (b as char).to_string()
            }
            b' ' => "+".to_string(),
            _ => format!("%{b:02X}"),
        })
        .collect()
}
