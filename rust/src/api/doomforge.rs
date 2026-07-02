//! flutter_rust_bridge API surface — the Flutter analogue of the old Tauri
//! command layer. Thin wrappers over the reused DoomForge domain/services
//! logic. The per-user data dir is injected once from Dart (path_provider).

use std::path::PathBuf;
use std::sync::RwLock;

use crate::models::*;
use crate::net::PackageEntry;
use crate::{
    ai, conflicts, engine, iwad, launch, load_order, logs, net, profile, recommend, report, scan,
    snapshots, stability,
};

static DATA_DIR: RwLock<Option<PathBuf>> = RwLock::new(None);

fn base() -> PathBuf {
    DATA_DIR
        .read()
        .unwrap()
        .clone()
        .unwrap_or_else(|| std::env::temp_dir().join("doomforge"))
}

fn e<T>(r: crate::error::AppResult<T>) -> anyhow::Result<T> {
    r.map_err(|err| anyhow::anyhow!(err.to_string()))
}

/// Store the per-user data directory (call once at startup from Dart).
pub fn set_data_dir(data_dir: String) {
    *DATA_DIR.write().unwrap() = Some(PathBuf::from(data_dir));
}

// ---- library ---------------------------------------------------------------
pub fn scan_mods(dir: String, with_hashes: bool) -> anyhow::Result<Vec<ModFile>> {
    e(scan::scan_dir(&dir, with_hashes))
}
pub fn describe_files(paths: Vec<String>) -> Vec<ModFile> {
    scan::describe_paths(&paths)
}
pub fn find_duplicates(files: Vec<ModFile>) -> Vec<DuplicateGroup> {
    scan::find_duplicates(&files)
}
pub fn search_mod_contents(files: Vec<ModFile>, query: String) -> anyhow::Result<Vec<String>> {
    e(scan::search_contents(&files, &query))
}

// ---- engines / iwads -------------------------------------------------------
pub fn scan_engines(dir: String) -> anyhow::Result<Vec<Engine>> {
    e(engine::scan_engines(&dir))
}
pub fn inspect_engine(path: String) -> anyhow::Result<Engine> {
    e(engine::inspect_engine(&path))
}
pub fn detect_engines() -> anyhow::Result<Vec<Engine>> {
    e(engine::detect_installed())
}
pub fn check_iwads(dirs: Vec<String>) -> Vec<Iwad> {
    iwad::check_iwads(&dirs)
}

// ---- profiles --------------------------------------------------------------
pub fn auto_order(entries: Vec<LoadEntry>) -> Vec<LoadEntry> {
    load_order::auto_order(&entries)
}
pub fn list_profiles() -> anyhow::Result<Vec<Profile>> {
    e(profile::list_profiles(&base()))
}
pub fn save_profile(profile: Profile) -> anyhow::Result<Profile> {
    e(profile::save_profile(&base(), profile))
}
pub fn delete_profile(id: String) -> anyhow::Result<()> {
    e(profile::delete_profile(&base(), &id))
}
pub fn export_profile(id: String, dest: String) -> anyhow::Result<()> {
    e(profile::export_profile(&base(), &id, &dest))
}
pub fn import_profile(src: String) -> anyhow::Result<Profile> {
    e(profile::import_profile(&base(), &src))
}
pub fn compare_profiles(a: Profile, b: Profile) -> ProfileDiff {
    report::diff(&a, &b)
}

// ---- builds ----------------------------------------------------------------
pub fn launch_profile(engine: String, profile: Profile, safe_mode: bool) -> anyhow::Result<String> {
    let preview =
        launch::launch(&engine, &profile, safe_mode).map_err(|err| anyhow::anyhow!(err.to_string()))?;
    profile::touch_played(&base(), &profile.id).map_err(|err| anyhow::anyhow!(err.to_string()))?;
    Ok(preview)
}
pub fn dry_run_profile(engine: String, profile: Profile) -> anyhow::Result<String> {
    e(launch::dry_run(&engine, &profile))
}
pub fn evaluate_compat(profile: Profile) -> CompatReport {
    conflicts::evaluate(&base(), &profile)
}
pub fn mod_graph(profile: Profile) -> ModGraph {
    conflicts::graph(&base(), &profile)
}
pub fn create_snapshot(profile: Profile, label: String) -> anyhow::Result<SnapshotMeta> {
    e(snapshots::create(&base(), &profile, &label))
}
pub fn list_snapshots(profile_id: String) -> anyhow::Result<Vec<SnapshotMeta>> {
    e(snapshots::list(&base(), &profile_id))
}
pub fn restore_snapshot(profile_id: String, snapshot_id: String) -> anyhow::Result<Profile> {
    e(snapshots::restore(&base(), &profile_id, &snapshot_id))
}
pub fn delete_snapshot(profile_id: String, snapshot_id: String) -> anyhow::Result<()> {
    e(snapshots::delete(&base(), &profile_id, &snapshot_id))
}
pub fn record_outcome(profile_id: String, crashed: bool) -> anyhow::Result<Stability> {
    e(stability::record(&base(), &profile_id, crashed))
}
pub fn get_stability(profile_id: String) -> Stability {
    stability::get(&base(), &profile_id)
}
pub fn recommend_mods(library: Vec<ModFile>, profile: Profile, limit: u32) -> Vec<Recommendation> {
    recommend::recommend(&library, &profile, limit as usize)
}
pub fn forge_build(library: Vec<ModFile>, iwad: Option<String>) -> anyhow::Result<Profile> {
    let p = recommend::forge_build(&library, iwad);
    e(profile::save_profile(&base(), p))
}
pub fn generate_report(profile: Profile) -> String {
    report::problem_report(&base(), &profile)
}
pub fn save_text(dest: String, contents: String) -> anyhow::Result<()> {
    std::fs::write(&dest, contents).map_err(|err| anyhow::anyhow!(err.to_string()))
}

// ---- analysis --------------------------------------------------------------
pub fn analyze_log_file(path: String, profile: Profile) -> anyhow::Result<LogAnalysis> {
    e(logs::analyze_file(&path, &profile))
}
pub fn analyze_log_text(text: String, profile: Profile) -> LogAnalysis {
    logs::analyze(&text, &profile)
}

// ---- network ---------------------------------------------------------------
pub fn catalog() -> Vec<PackageEntry> {
    net::builtin_catalog()
}
pub fn install_catalog(url: String, mods_dir: String) -> anyhow::Result<String> {
    e(net::install_catalog(&url, &mods_dir))
}
pub fn search_registry(source: String, query: String) -> anyhow::Result<Vec<PackageEntry>> {
    e(net::search_registry(&source, &query))
}
pub fn install_package(source: String, id: String, mods_dir: String) -> anyhow::Result<String> {
    e(net::install_package(&source, &id, &mods_dir))
}
pub fn import_by_url(url: String, dest_dir: String) -> anyhow::Result<String> {
    e(net::download_mod(&url, &dest_dir))
}
pub fn install_freedoom(iwad_dir: String) -> anyhow::Result<Vec<String>> {
    e(net::install_freedoom(&iwad_dir))
}
pub fn install_gzdoom(dest_dir: String) -> anyhow::Result<String> {
    e(net::install_gzdoom(&dest_dir))
}
pub fn idgames_search(query: String) -> anyhow::Result<Vec<PackageEntry>> {
    e(net::idgames_search(&query))
}

// ---- ai --------------------------------------------------------------------
pub fn ai_analyze_log(api_key: String, model: String, log: String, load_order: Vec<String>) -> anyhow::Result<String> {
    e(ai::analyze_log(&api_key, &model, &log, &load_order))
}
pub fn ai_describe_build(api_key: String, model: String, mods: Vec<String>) -> anyhow::Result<String> {
    e(ai::describe_build(&api_key, &model, &mods))
}
