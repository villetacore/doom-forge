use crate::error::AppResult;
use crate::models::{Engine, Iwad};
use crate::{engine, iwad};

#[tauri::command]
pub fn scan_engines(dir: String) -> AppResult<Vec<Engine>> {
    engine::scan_engines(&dir)
}

#[tauri::command]
pub fn inspect_engine(path: String) -> AppResult<Engine> {
    engine::inspect_engine(&path)
}

#[tauri::command]
pub fn detect_engines() -> AppResult<Vec<Engine>> {
    engine::detect_installed()
}

#[tauri::command]
pub fn check_iwads(dirs: Vec<String>) -> Vec<Iwad> {
    iwad::check_iwads(&dirs)
}
