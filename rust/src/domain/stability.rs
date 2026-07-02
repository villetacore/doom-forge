use std::collections::HashMap;
use std::fs;
use std::path::Path;

use crate::error::AppResult;
use crate::models::Stability;

type Db = HashMap<String, Stability>;

fn db_path(base: &Path) -> std::path::PathBuf {
    base.join("stability.json")
}

fn load(base: &Path) -> Db {
    fs::read_to_string(db_path(base))
        .ok()
        .and_then(|t| serde_json::from_str(&t).ok())
        .unwrap_or_default()
}

fn save(base: &Path, db: &Db) -> AppResult<()> {
    fs::write(db_path(base), serde_json::to_string_pretty(db)?)?;
    Ok(())
}

fn rating(launches: u32, crashes: u32) -> u8 {
    if launches == 0 {
        return 100;
    }
    let ok = launches.saturating_sub(crashes) as f32;
    ((ok / launches as f32) * 100.0).round() as u8
}

/// Record a launch outcome and return the updated stats for the profile.
pub fn record(base: &Path, profile_id: &str, crashed: bool) -> AppResult<Stability> {
    let mut db = load(base);
    let entry = db.entry(profile_id.to_string()).or_default();
    entry.launches += 1;
    if crashed {
        entry.crashes += 1;
    }
    entry.rating = rating(entry.launches, entry.crashes);
    let result = entry.clone();
    save(base, &db)?;
    Ok(result)
}

pub fn get(base: &Path, profile_id: &str) -> Stability {
    load(base).get(profile_id).cloned().unwrap_or_default()
}
