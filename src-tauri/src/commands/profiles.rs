use crate::error::AppResult;
use crate::models::{LoadEntry, Profile, ProfileDiff};
use crate::{load_order, profile, report};

use super::data_dir;

#[tauri::command]
pub fn auto_order(entries: Vec<LoadEntry>) -> Vec<LoadEntry> {
    load_order::auto_order(&entries)
}

#[tauri::command]
pub fn list_profiles(app: tauri::AppHandle) -> AppResult<Vec<Profile>> {
    profile::list_profiles(&data_dir(&app)?)
}

#[tauri::command]
pub fn save_profile(app: tauri::AppHandle, profile: Profile) -> AppResult<Profile> {
    profile::save_profile(&data_dir(&app)?, profile)
}

#[tauri::command]
pub fn delete_profile(app: tauri::AppHandle, id: String) -> AppResult<()> {
    profile::delete_profile(&data_dir(&app)?, &id)
}

#[tauri::command]
pub fn export_profile(app: tauri::AppHandle, id: String, dest: String) -> AppResult<()> {
    profile::export_profile(&data_dir(&app)?, &id, &dest)
}

#[tauri::command]
pub fn import_profile(app: tauri::AppHandle, src: String) -> AppResult<Profile> {
    profile::import_profile(&data_dir(&app)?, &src)
}

#[tauri::command]
pub fn compare_profiles(a: Profile, b: Profile) -> ProfileDiff {
    report::diff(&a, &b)
}
