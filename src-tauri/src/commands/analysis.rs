use crate::error::AppResult;
use crate::logs;
use crate::models::{LogAnalysis, Profile};

#[tauri::command]
pub fn analyze_log_file(path: String, profile: Profile) -> AppResult<LogAnalysis> {
    logs::analyze_file(&path, &profile)
}

#[tauri::command]
pub fn analyze_log_text(text: String, profile: Profile) -> LogAnalysis {
    logs::analyze(&text, &profile)
}
