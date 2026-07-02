use std::collections::HashMap;
use std::fs::File;
use std::io::Read;
use std::path::Path;

use sha2::{Digest, Sha256};
use walkdir::WalkDir;

use crate::error::AppResult;
use crate::models::{DuplicateGroup, ModFile, ModGroup};

/// Recognised mod container / patch extensions.
const MOD_EXTS: &[&str] = &["pk3", "pk7", "wad", "zip", "pke", "ipk3", "deh", "bex"];

/// Guess a mod's group from filename keywords. This feeds the auto load-order
/// heuristic; the user can always override it in the UI.
fn classify(name: &str, ext: &str) -> ModGroup {
    let n = name.to_lowercase();
    if ext == "deh" || ext == "bex" || n.contains("patch") || n.contains("compat") {
        return ModGroup::Patch;
    }
    let has = |keys: &[&str]| keys.iter().any(|k| n.contains(k));
    if has(&["map", "level", "episode", "wad", "megawad", "eviternity", "sunlust"]) && ext == "wad"
    {
        return ModGroup::Maps;
    }
    if has(&["music", "sound", "sndtrk", "ost", "audio", "sfx"]) {
        return ModGroup::Audio;
    }
    if has(&[
        "hud", "texture", "brightmaps", "lights", "hires", "smooth", "gore", "blood", "visual",
        "skybox", "fullscreen",
    ]) {
        return ModGroup::Visuals;
    }
    if has(&[
        "brutal", "weapon", "gameplay", "monsters", "enemies", "guncaster", "doomrl", "complex",
    ]) {
        return ModGroup::Gameplay;
    }
    match ext {
        "wad" => ModGroup::Maps,
        _ => ModGroup::Other,
    }
}

/// Scan a directory tree for mod files. `with_hashes` controls whether SHA-256
/// is computed (slower, but required for accurate duplicate detection).
pub fn scan_dir(dir: &str, with_hashes: bool) -> AppResult<Vec<ModFile>> {
    let mut out = Vec::new();
    for entry in WalkDir::new(dir).into_iter().filter_map(|e| e.ok()) {
        if !entry.file_type().is_file() {
            continue;
        }
        let path = entry.path();
        let ext = path
            .extension()
            .and_then(|e| e.to_str())
            .map(|e| e.to_lowercase())
            .unwrap_or_default();
        if !MOD_EXTS.contains(&ext.as_str()) {
            continue;
        }
        let name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or_default()
            .to_string();
        let size = entry.metadata().map(|m| m.len()).unwrap_or(0);
        let sha256 = if with_hashes {
            hash_file(path).ok()
        } else {
            None
        };
        out.push(ModFile {
            path: path.to_string_lossy().to_string(),
            group: classify(&name, &ext),
            name,
            extension: ext,
            size,
            sha256,
            tags: Vec::new(),
        });
    }
    out.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
    Ok(out)
}

/// Describe explicitly chosen files (e.g. picked via a file dialog) as
/// `ModFile`s, without scanning a whole directory. Non-mod files are skipped.
pub fn describe_paths(paths: &[String]) -> Vec<ModFile> {
    let mut out = Vec::new();
    for p in paths {
        let path = Path::new(p);
        let ext = path
            .extension()
            .and_then(|e| e.to_str())
            .map(|e| e.to_lowercase())
            .unwrap_or_default();
        if !MOD_EXTS.contains(&ext.as_str()) {
            continue;
        }
        let name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or_default()
            .to_string();
        let size = std::fs::metadata(path).map(|m| m.len()).unwrap_or(0);
        out.push(ModFile {
            path: path.to_string_lossy().to_string(),
            group: classify(&name, &ext),
            name,
            extension: ext,
            size,
            sha256: None,
            tags: Vec::new(),
        });
    }
    out
}

fn hash_file(path: &Path) -> AppResult<String> {
    let mut file = File::open(path)?;
    let mut hasher = Sha256::new();
    let mut buf = [0u8; 64 * 1024];
    loop {
        let n = file.read(&mut buf)?;
        if n == 0 {
            break;
        }
        hasher.update(&buf[..n]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

/// Find duplicate mods. Files with an identical SHA-256 are exact duplicates;
/// files sharing a name but differing in size are flagged as likely versions.
pub fn find_duplicates(files: &[ModFile]) -> Vec<DuplicateGroup> {
    let mut groups = Vec::new();

    let mut by_hash: HashMap<&str, Vec<&ModFile>> = HashMap::new();
    for f in files {
        if let Some(h) = &f.sha256 {
            by_hash.entry(h.as_str()).or_default().push(f);
        }
    }
    for (_, fs) in by_hash {
        if fs.len() > 1 {
            groups.push(DuplicateGroup {
                reason: "Identical content (same SHA-256)".into(),
                files: fs.iter().map(|f| f.path.clone()).collect(),
            });
        }
    }

    let mut by_name: HashMap<String, Vec<&ModFile>> = HashMap::new();
    for f in files {
        by_name.entry(f.name.to_lowercase()).or_default().push(f);
    }
    for (name, fs) in by_name {
        if fs.len() > 1 {
            groups.push(DuplicateGroup {
                reason: format!("Same filename in multiple locations: {name}"),
                files: fs.iter().map(|f| f.path.clone()).collect(),
            });
        }
    }

    groups
}

/// Search inside PK3/WAD/ZIP containers for an entry whose name matches `query`.
/// Returns the list of archive paths that contain a match.
pub fn search_contents(files: &[ModFile], query: &str) -> AppResult<Vec<String>> {
    let q = query.to_lowercase();
    let mut hits = Vec::new();
    for f in files {
        let is_zip = matches!(f.extension.as_str(), "pk3" | "pk7" | "zip" | "pke" | "ipk3");
        if !is_zip {
            continue;
        }
        if archive_contains(&f.path, &q).unwrap_or(false) {
            hits.push(f.path.clone());
        }
    }
    Ok(hits)
}

fn archive_contains(path: &str, query_lower: &str) -> AppResult<bool> {
    let file = File::open(path)?;
    let mut zip = zip::ZipArchive::new(file)?;
    for i in 0..zip.len() {
        let entry = zip.by_index(i)?;
        if entry.name().to_lowercase().contains(query_lower) {
            return Ok(true);
        }
    }
    Ok(false)
}
