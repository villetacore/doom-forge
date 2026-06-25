//! Tauri command layer: thin handlers that adapt the domain/services to the
//! frontend. Grouped by area; registered in `lib.rs`.

pub mod ai;
pub mod analysis;
pub mod builds;
pub mod engines;
pub mod library;
pub mod network;
pub mod profiles;

use std::path::PathBuf;

use crate::error::{AppError, AppResult};

/// Resolve the per-user data directory where profiles & state live.
pub(crate) fn data_dir(app: &tauri::AppHandle) -> AppResult<PathBuf> {
    use tauri::Manager;
    app.path()
        .app_data_dir()
        .map_err(|e| AppError::msg(format!("No app data dir: {e}")))
}
