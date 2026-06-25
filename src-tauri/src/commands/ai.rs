use crate::ai;
use crate::error::AppResult;

#[tauri::command]
pub fn ai_analyze_log(
    api_key: String,
    model: String,
    log: String,
    load_order: Vec<String>,
) -> AppResult<String> {
    ai::analyze_log(&api_key, &model, &log, &load_order)
}

#[tauri::command]
pub fn ai_describe_build(api_key: String, model: String, mods: Vec<String>) -> AppResult<String> {
    ai::describe_build(&api_key, &model, &mods)
}
