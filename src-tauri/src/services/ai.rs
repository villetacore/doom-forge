use serde_json::json;

use crate::error::{AppError, AppResult};

/// Minimal Claude API (Anthropic Messages API) client. The API key and model
/// are supplied by the caller (configured in app settings) — DoomForge ships
/// no key. Default model: claude-opus-4-8.
///
/// Used for AI log analysis, build descriptions, conflict reasoning, etc.
/// All AI features degrade gracefully to the local heuristics when no key set.
pub fn complete(api_key: &str, model: &str, system: &str, user: &str) -> AppResult<String> {
    if api_key.trim().is_empty() {
        return Err(AppError::msg("No Claude API key configured (Settings → AI)"));
    }
    let model = if model.trim().is_empty() {
        "claude-opus-4-8"
    } else {
        model
    };

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(120))
        .build()
        .map_err(|e| AppError::msg(e.to_string()))?;

    let body = json!({
        "model": model,
        "max_tokens": 1024,
        "system": system,
        "messages": [{ "role": "user", "content": user }]
    });

    let resp = client
        .post("https://api.anthropic.com/v1/messages")
        .header("x-api-key", api_key)
        .header("anthropic-version", "2023-06-01")
        .header("content-type", "application/json")
        .json(&body)
        .send()
        .map_err(|e| AppError::msg(e.to_string()))?;

    let status = resp.status();
    let value: serde_json::Value = resp.json().map_err(|e| AppError::msg(e.to_string()))?;
    if !status.is_success() {
        let msg = value["error"]["message"].as_str().unwrap_or("unknown error");
        return Err(AppError::msg(format!("Claude API {status}: {msg}")));
    }

    // Concatenate text blocks from the response content array.
    let text = value["content"]
        .as_array()
        .map(|blocks| {
            blocks
                .iter()
                .filter_map(|b| b["text"].as_str())
                .collect::<Vec<_>>()
                .join("")
        })
        .unwrap_or_default();
    if text.is_empty() {
        return Err(AppError::msg("Empty response from Claude API"));
    }
    Ok(text)
}

/// AI crash-log analysis: feed the log + load order, get a human explanation.
pub fn analyze_log(api_key: &str, model: &str, log: &str, load_order: &[String]) -> AppResult<String> {
    let system = "You are a GZDoom troubleshooting expert. Given a crash log and \
        the mod load order, identify the most likely culprit mod and explain the \
        fix concisely. Be specific and actionable.";
    let user = format!(
        "Load order (in order):\n{}\n\nCrash log:\n{}",
        load_order.join("\n"),
        // Cap the log to keep the request small.
        &log.chars().take(8000).collect::<String>()
    );
    complete(api_key, model, system, &user)
}

/// AI build description generator.
pub fn describe_build(api_key: &str, model: &str, mods: &[String]) -> AppResult<String> {
    let system = "You write punchy, evocative descriptions of GZDoom mod builds, \
        2-4 sentences, like a curator's note. No preamble.";
    let user = format!("Mods in this build:\n{}", mods.join("\n"));
    complete(api_key, model, system, &user)
}
