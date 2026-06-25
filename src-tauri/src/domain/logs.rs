use std::fs;

use crate::error::AppResult;
use crate::models::{LogAnalysis, Profile};

/// Heuristic crash-log analyser. Reads a GZDoom log/crash file and tries to
/// name the culprit by correlating error lines with the profile's load order.
///
/// GZDoom errors typically mention a lump, script (ZScript/DECORATE/ACS) or
/// file name; we match those tokens against the enabled mods.
pub fn analyze(log_text: &str, profile: &Profile) -> LogAnalysis {
    let lower = log_text.to_lowercase();
    let mut signals = Vec::new();

    const MARKERS: &[(&str, &str)] = &[
        ("vm execution aborted", "ZScript VM abort (script runtime error)"),
        ("script error", "Script compilation error (DECORATE/ZScript)"),
        ("execution could not continue", "Fatal startup error"),
        ("tried to register class", "Duplicate class definition — two mods clash"),
        ("unknown actor", "Missing actor — a dependency mod is absent"),
        ("bad sprite", "Broken/duplicate sprite data"),
        ("r_drawcolumn", "Renderer crash (often visuals/texture mod)"),
        ("out of memory", "Out of memory"),
        ("access violation", "Native crash (engine/driver)"),
    ];
    for (needle, human) in MARKERS {
        if lower.contains(needle) {
            signals.push(human.to_string());
        }
    }

    // Score each enabled mod by how often its name (sans extension) appears in
    // the log, weighted heavier near error lines.
    let mut scored: Vec<(String, u32)> = Vec::new();
    for entry in profile.load_order.iter().filter(|e| e.enabled) {
        let stem = entry
            .name
            .rsplit_once('.')
            .map(|(s, _)| s)
            .unwrap_or(&entry.name)
            .to_lowercase();
        if stem.len() < 3 {
            continue;
        }
        let count = lower.matches(&stem).count() as u32;
        if count > 0 {
            scored.push((entry.name.clone(), count));
        }
    }
    scored.sort_by(|a, b| b.1.cmp(&a.1));
    let suspect_mods: Vec<String> = scored.into_iter().map(|(n, _)| n).collect();

    let summary = if signals.is_empty() && suspect_mods.is_empty() {
        "No obvious crash signature found. The log may be a clean exit.".to_string()
    } else if suspect_mods.is_empty() {
        format!("Detected: {}. No specific mod named in the log.", signals.join("; "))
    } else {
        format!(
            "Detected: {}. Most likely culprit: {}.",
            if signals.is_empty() { "an error".into() } else { signals.join("; ") },
            suspect_mods[0]
        )
    };

    LogAnalysis {
        summary,
        suspect_mods,
        signals,
    }
}

/// Analyse a log file on disk.
pub fn analyze_file(path: &str, profile: &Profile) -> AppResult<LogAnalysis> {
    let text = fs::read_to_string(path)?;
    Ok(analyze(&text, profile))
}
