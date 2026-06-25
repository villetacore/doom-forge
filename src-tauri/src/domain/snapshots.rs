use std::fs;
use std::path::{Path, PathBuf};

use crate::error::{AppError, AppResult};
use crate::models::{Profile, SnapshotMeta};
use crate::profile::now_iso;

/// Snapshots for a profile live under `profiles/<id>.snapshots/`.
fn snap_dir(base: &Path, profile_id: &str) -> PathBuf {
    base.join("profiles").join(format!("{profile_id}.snapshots"))
}

/// Capture the current state of a profile as an immutable snapshot.
pub fn create(base: &Path, profile: &Profile, label: &str) -> AppResult<SnapshotMeta> {
    let dir = snap_dir(base, &profile.id);
    fs::create_dir_all(&dir)?;
    let id = format!("{}", chrono::Utc::now().timestamp_millis());
    let meta = SnapshotMeta {
        id: id.clone(),
        label: if label.is_empty() {
            format!("Snapshot {id}")
        } else {
            label.to_string()
        },
        created_at: now_iso(),
        entry_count: profile.load_order.len(),
    };
    // Store the full profile body alongside the metadata in one file.
    let payload = serde_json::json!({ "meta": meta, "profile": profile });
    fs::write(
        dir.join(format!("{id}.json")),
        serde_json::to_string_pretty(&payload)?,
    )?;
    Ok(meta)
}

/// List snapshots for a profile, newest first.
pub fn list(base: &Path, profile_id: &str) -> AppResult<Vec<SnapshotMeta>> {
    let dir = snap_dir(base, profile_id);
    if !dir.exists() {
        return Ok(Vec::new());
    }
    let mut metas = Vec::new();
    for entry in fs::read_dir(&dir)? {
        let path = entry?.path();
        if path.extension().and_then(|e| e.to_str()) == Some("json") {
            if let Ok(text) = fs::read_to_string(&path) {
                if let Ok(v) = serde_json::from_str::<serde_json::Value>(&text) {
                    if let Ok(meta) = serde_json::from_value::<SnapshotMeta>(v["meta"].clone()) {
                        metas.push(meta);
                    }
                }
            }
        }
    }
    metas.sort_by(|a, b| b.id.cmp(&a.id));
    Ok(metas)
}

/// Restore a snapshot's stored profile body (keeping the original id).
pub fn restore(base: &Path, profile_id: &str, snapshot_id: &str) -> AppResult<Profile> {
    let path = snap_dir(base, profile_id).join(format!("{snapshot_id}.json"));
    let text = fs::read_to_string(&path).map_err(|_| AppError::msg("Snapshot not found"))?;
    let v: serde_json::Value = serde_json::from_str(&text)?;
    let mut profile: Profile = serde_json::from_value(v["profile"].clone())
        .map_err(|_| AppError::msg("Corrupt snapshot"))?;
    profile.id = profile_id.to_string();
    crate::profile::save_profile(base, profile)
}

pub fn delete(base: &Path, profile_id: &str, snapshot_id: &str) -> AppResult<()> {
    let path = snap_dir(base, profile_id).join(format!("{snapshot_id}.json"));
    if path.exists() {
        fs::remove_file(path)?;
    }
    Ok(())
}
