use crate::error::AppResult;
use crate::models::{
    CompatReport, ModFile, ModGraph, Profile, Recommendation, SnapshotMeta, Stability,
};
use crate::{conflicts, launch, profile, recommend, report, snapshots, stability};

use super::data_dir;

// ---- Launching -------------------------------------------------------------

#[tauri::command]
pub fn launch_profile(
    app: tauri::AppHandle,
    engine: String,
    profile: Profile,
    safe_mode: bool,
) -> AppResult<String> {
    let preview = launch::launch(&engine, &profile, safe_mode)?;
    profile::touch_played(&data_dir(&app)?, &profile.id)?;
    Ok(preview)
}

#[tauri::command]
pub fn dry_run_profile(engine: String, profile: Profile) -> AppResult<String> {
    launch::dry_run(&engine, &profile)
}

// ---- Conflicts / compatibility / graph -------------------------------------

#[tauri::command]
pub fn evaluate_compat(app: tauri::AppHandle, profile: Profile) -> AppResult<CompatReport> {
    Ok(conflicts::evaluate(&data_dir(&app)?, &profile))
}

#[tauri::command]
pub fn mod_graph(app: tauri::AppHandle, profile: Profile) -> AppResult<ModGraph> {
    Ok(conflicts::graph(&data_dir(&app)?, &profile))
}

// ---- Snapshots -------------------------------------------------------------

#[tauri::command]
pub fn create_snapshot(
    app: tauri::AppHandle,
    profile: Profile,
    label: String,
) -> AppResult<SnapshotMeta> {
    snapshots::create(&data_dir(&app)?, &profile, &label)
}

#[tauri::command]
pub fn list_snapshots(app: tauri::AppHandle, profile_id: String) -> AppResult<Vec<SnapshotMeta>> {
    snapshots::list(&data_dir(&app)?, &profile_id)
}

#[tauri::command]
pub fn restore_snapshot(
    app: tauri::AppHandle,
    profile_id: String,
    snapshot_id: String,
) -> AppResult<Profile> {
    snapshots::restore(&data_dir(&app)?, &profile_id, &snapshot_id)
}

#[tauri::command]
pub fn delete_snapshot(
    app: tauri::AppHandle,
    profile_id: String,
    snapshot_id: String,
) -> AppResult<()> {
    snapshots::delete(&data_dir(&app)?, &profile_id, &snapshot_id)
}

// ---- Stability -------------------------------------------------------------

#[tauri::command]
pub fn record_outcome(
    app: tauri::AppHandle,
    profile_id: String,
    crashed: bool,
) -> AppResult<Stability> {
    stability::record(&data_dir(&app)?, &profile_id, crashed)
}

#[tauri::command]
pub fn get_stability(app: tauri::AppHandle, profile_id: String) -> AppResult<Stability> {
    Ok(stability::get(&data_dir(&app)?, &profile_id))
}

// ---- Recommendations / auto-build ------------------------------------------

#[tauri::command]
pub fn recommend_mods(
    library: Vec<ModFile>,
    profile: Profile,
    limit: usize,
) -> Vec<Recommendation> {
    recommend::recommend(&library, &profile, limit)
}

#[tauri::command]
pub fn forge_build(
    app: tauri::AppHandle,
    library: Vec<ModFile>,
    iwad: Option<String>,
) -> AppResult<Profile> {
    let p = recommend::forge_build(&library, iwad);
    profile::save_profile(&data_dir(&app)?, p)
}

// ---- Reports ---------------------------------------------------------------

#[tauri::command]
pub fn generate_report(app: tauri::AppHandle, profile: Profile) -> AppResult<String> {
    Ok(report::problem_report(&data_dir(&app)?, &profile))
}

#[tauri::command]
pub fn save_text(dest: String, contents: String) -> AppResult<()> {
    std::fs::write(&dest, contents)?;
    Ok(())
}
