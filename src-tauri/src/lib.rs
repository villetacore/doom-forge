//! DoomForge library crate: wires the domain logic and services to the Tauri
//! command surface. Also reused by the `doom` CLI binary.

pub mod error;

pub mod domain;
pub mod services;

mod commands;

// Flatten the domain/services modules to the crate root so existing
// `crate::scan`, `crate::models`, `crate::net`, … paths keep resolving and the
// `doom` CLI can import them directly.
pub use domain::{
    conflicts, engine, iwad, launch, load_order, logs, models, profile, recommend, report, scan,
    snapshots, stability,
};
pub use services::{ai, net};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            // library
            commands::library::scan_mods,
            commands::library::describe_files,
            commands::library::find_duplicates,
            commands::library::search_mod_contents,
            // engines / iwads
            commands::engines::scan_engines,
            commands::engines::inspect_engine,
            commands::engines::detect_engines,
            commands::engines::check_iwads,
            // profiles
            commands::profiles::auto_order,
            commands::profiles::list_profiles,
            commands::profiles::save_profile,
            commands::profiles::delete_profile,
            commands::profiles::export_profile,
            commands::profiles::import_profile,
            commands::profiles::compare_profiles,
            // builds
            commands::builds::launch_profile,
            commands::builds::dry_run_profile,
            commands::builds::evaluate_compat,
            commands::builds::mod_graph,
            commands::builds::create_snapshot,
            commands::builds::list_snapshots,
            commands::builds::restore_snapshot,
            commands::builds::delete_snapshot,
            commands::builds::record_outcome,
            commands::builds::get_stability,
            commands::builds::recommend_mods,
            commands::builds::forge_build,
            commands::builds::generate_report,
            commands::builds::save_text,
            // analysis
            commands::analysis::analyze_log_file,
            commands::analysis::analyze_log_text,
            // network
            commands::network::catalog,
            commands::network::install_catalog,
            commands::network::search_registry,
            commands::network::install_package,
            commands::network::import_by_url,
            commands::network::install_freedoom,
            commands::network::install_gzdoom,
            commands::network::idgames_search,
            // ai
            commands::ai::ai_analyze_log,
            commands::ai::ai_describe_build,
        ])
        .run(tauri::generate_context!())
        .expect("error while running DoomForge");
}
