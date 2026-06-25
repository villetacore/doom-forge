use std::process::Command;

use crate::error::{AppError, AppResult};
use crate::models::Profile;

/// Build the GZDoom command-line arguments for a profile.
///
/// `safe_mode` adds flags that disable auto-loading and saved configs, useful
/// for diagnosing a crashing build (the "Safe mode" launch button in the UI).
pub fn build_args(profile: &Profile, safe_mode: bool) -> AppResult<Vec<String>> {
    let mut args: Vec<String> = Vec::new();

    if let Some(iwad) = &profile.iwad {
        args.push("-iwad".into());
        args.push(iwad.clone());
    } else {
        return Err(AppError::msg("Profile has no IWAD selected"));
    }

    let files: Vec<String> = profile
        .load_order
        .iter()
        .filter(|e| e.enabled)
        .map(|e| e.path.clone())
        .collect();
    if !files.is_empty() {
        args.push("-file".into());
        args.extend(files);
    }

    if safe_mode {
        // Don't pull in ini autoloads or the saved config when triaging crashes.
        args.push("-noautoload".into());
        args.push("+vid_renderer".into());
        args.push("0".into());
    }

    args.extend(profile.extra_args.iter().cloned());
    Ok(args)
}

/// Spawn the engine for a profile. Returns the launched command line as a
/// single string for display/logging. Does not wait for the process to exit.
pub fn launch(engine: &str, profile: &Profile, safe_mode: bool) -> AppResult<String> {
    let args = build_args(profile, safe_mode)?;
    let mut cmd = Command::new(engine);
    cmd.args(&args);
    cmd.spawn()
        .map_err(|e| AppError::msg(format!("Failed to start engine: {e}")))?;
    let preview = format!("{} {}", engine, args.join(" "));
    Ok(preview)
}

/// Dry-run / "autotest": validate that the engine and files exist and the
/// command line builds, without actually starting the game.
pub fn dry_run(engine: &str, profile: &Profile) -> AppResult<String> {
    if !std::path::Path::new(engine).is_file() {
        return Err(AppError::msg("Engine executable not found"));
    }
    for entry in profile.load_order.iter().filter(|e| e.enabled) {
        if !std::path::Path::new(&entry.path).is_file() {
            return Err(AppError::msg(format!("Missing mod file: {}", entry.name)));
        }
    }
    let args = build_args(profile, false)?;
    Ok(format!("{} {}", engine, args.join(" ")))
}
