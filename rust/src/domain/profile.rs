use std::fs;
use std::path::{Path, PathBuf};

use chrono::Utc;

use crate::error::{AppError, AppResult};
use crate::models::Profile;

/// Directory under the app data dir where profiles are stored, one JSON each.
fn profiles_dir(base: &Path) -> PathBuf {
    base.join("profiles")
}

fn ensure_dir(dir: &Path) -> AppResult<()> {
    if !dir.exists() {
        fs::create_dir_all(dir)?;
    }
    Ok(())
}

pub fn now_iso() -> String {
    Utc::now().to_rfc3339()
}

/// Load every saved profile, newest-updated first.
pub fn list_profiles(base: &Path) -> AppResult<Vec<Profile>> {
    let dir = profiles_dir(base);
    if !dir.exists() {
        return Ok(Vec::new());
    }
    let mut profiles = Vec::new();
    for entry in fs::read_dir(&dir)? {
        let path = entry?.path();
        if path.extension().and_then(|e| e.to_str()) == Some("json") {
            if let Ok(text) = fs::read_to_string(&path) {
                if let Ok(p) = serde_json::from_str::<Profile>(&text) {
                    profiles.push(p);
                }
            }
        }
    }
    profiles.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
    Ok(profiles)
}

/// Create or overwrite a profile, stamping `updated_at`.
pub fn save_profile(base: &Path, mut profile: Profile) -> AppResult<Profile> {
    let dir = profiles_dir(base);
    ensure_dir(&dir)?;
    profile.updated_at = now_iso();
    let path = dir.join(format!("{}.json", profile.id));
    fs::write(&path, serde_json::to_string_pretty(&profile)?)?;
    Ok(profile)
}

pub fn delete_profile(base: &Path, id: &str) -> AppResult<()> {
    let path = profiles_dir(base).join(format!("{id}.json"));
    if path.exists() {
        fs::remove_file(path)?;
    }
    Ok(())
}

/// Export a profile to a standalone `.dfprofile` (JSON) file at `dest`.
pub fn export_profile(base: &Path, id: &str, dest: &str) -> AppResult<()> {
    let path = profiles_dir(base).join(format!("{id}.json"));
    let text = fs::read_to_string(&path)
        .map_err(|_| AppError::msg("Profile not found for export"))?;
    fs::write(dest, text)?;
    Ok(())
}

/// Import a `.dfprofile`/JSON file as a new profile (fresh id + timestamps).
pub fn import_profile(base: &Path, src: &str) -> AppResult<Profile> {
    let text = fs::read_to_string(src)?;
    let mut profile: Profile = serde_json::from_str(&text)
        .map_err(|_| AppError::msg("File is not a valid DoomForge profile"))?;
    profile.id = uuid::Uuid::new_v4().to_string();
    profile.created_at = now_iso();
    profile.last_played_at = None;
    save_profile(base, profile)
}

/// Mark a profile as just-played (updates `last_played_at`).
pub fn touch_played(base: &Path, id: &str) -> AppResult<()> {
    let dir = profiles_dir(base);
    let path = dir.join(format!("{id}.json"));
    if let Ok(text) = fs::read_to_string(&path) {
        if let Ok(mut p) = serde_json::from_str::<Profile>(&text) {
            p.last_played_at = Some(now_iso());
            fs::write(&path, serde_json::to_string_pretty(&p)?)?;
        }
    }
    Ok(())
}
