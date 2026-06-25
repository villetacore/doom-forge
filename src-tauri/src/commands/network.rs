use crate::error::AppResult;
use crate::net::{self, PackageEntry};

#[tauri::command]
pub fn catalog() -> Vec<PackageEntry> {
    net::builtin_catalog()
}

#[tauri::command]
pub fn install_catalog(url: String, mods_dir: String) -> AppResult<String> {
    net::install_catalog(&url, &mods_dir)
}

#[tauri::command]
pub fn search_registry(source: String, query: String) -> AppResult<Vec<PackageEntry>> {
    net::search_registry(&source, &query)
}

#[tauri::command]
pub fn install_package(source: String, id: String, mods_dir: String) -> AppResult<String> {
    net::install_package(&source, &id, &mods_dir)
}

#[tauri::command]
pub fn import_by_url(url: String, dest_dir: String) -> AppResult<String> {
    net::download_mod(&url, &dest_dir)
}

#[tauri::command]
pub fn install_freedoom(iwad_dir: String) -> AppResult<Vec<String>> {
    net::install_freedoom(&iwad_dir)
}

#[tauri::command]
pub fn install_gzdoom(dest_dir: String) -> AppResult<String> {
    net::install_gzdoom(&dest_dir)
}

#[tauri::command]
pub fn idgames_search(query: String) -> AppResult<Vec<PackageEntry>> {
    net::idgames_search(&query)
}
