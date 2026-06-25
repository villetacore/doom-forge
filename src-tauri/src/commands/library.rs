use crate::error::AppResult;
use crate::models::{DuplicateGroup, ModFile};
use crate::scan;

#[tauri::command]
pub fn scan_mods(dir: String, with_hashes: bool) -> AppResult<Vec<ModFile>> {
    scan::scan_dir(&dir, with_hashes)
}

/// Describe explicitly chosen files (picked via a file dialog) as mods.
#[tauri::command]
pub fn describe_files(paths: Vec<String>) -> Vec<ModFile> {
    scan::describe_paths(&paths)
}

#[tauri::command]
pub fn find_duplicates(files: Vec<ModFile>) -> Vec<DuplicateGroup> {
    scan::find_duplicates(&files)
}

#[tauri::command]
pub fn search_mod_contents(files: Vec<ModFile>, query: String) -> AppResult<Vec<String>> {
    scan::search_contents(&files, &query)
}
