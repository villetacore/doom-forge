use std::path::Path;
use std::process::Command;

use regex::Regex;
use walkdir::WalkDir;

use crate::error::AppResult;
use crate::models::Engine;

/// Executable names we treat as GZDoom-family source ports.
#[cfg(target_os = "windows")]
const ENGINE_BINS: &[&str] = &["gzdoom.exe", "lzdoom.exe", "zandronum.exe", "vkdoom.exe"];
#[cfg(not(target_os = "windows"))]
const ENGINE_BINS: &[&str] = &["gzdoom", "lzdoom", "zandronum", "vkdoom"];

fn is_engine_bin(file_name: &str) -> bool {
    let f = file_name.to_lowercase();
    ENGINE_BINS.iter().any(|b| f == *b)
}

/// Try to read the engine version by running `--version`. GZDoom prints
/// something like "GZDoom g4.12.2 - ...".
pub fn detect_version(exe: &str) -> Option<String> {
    let output = Command::new(exe).arg("--version").output().ok()?;
    let text = String::from_utf8_lossy(&output.stdout);
    let combined = if text.trim().is_empty() {
        String::from_utf8_lossy(&output.stderr).to_string()
    } else {
        text.to_string()
    };
    let re = Regex::new(r"g?(\d+\.\d+(?:\.\d+)?)").ok()?;
    re.captures(&combined)
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
}

fn make_engine(path: &Path) -> Engine {
    let p = path.to_string_lossy().to_string();
    Engine {
        name: path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("engine")
            .to_string(),
        version: detect_version(&p),
        path: p,
    }
}

/// Scan a directory tree for known engine executables.
pub fn scan_engines(dir: &str) -> AppResult<Vec<Engine>> {
    let mut out = Vec::new();
    for entry in WalkDir::new(dir)
        .max_depth(4)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        if !entry.file_type().is_file() {
            continue;
        }
        let name = entry.file_name().to_string_lossy().to_string();
        if is_engine_bin(&name) {
            out.push(make_engine(entry.path()));
        }
    }
    Ok(out)
}

/// Auto-detect engines on the system PATH and in common install locations,
/// without the user having to pick a folder.
pub fn detect_installed() -> AppResult<Vec<Engine>> {
    let mut found: Vec<Engine> = Vec::new();
    let mut seen = std::collections::HashSet::new();

    let mut consider = |path: std::path::PathBuf, found: &mut Vec<Engine>| {
        if path.is_file() {
            let canon = path.canonicalize().unwrap_or(path.clone());
            if seen.insert(canon.to_string_lossy().to_string()) {
                found.push(make_engine(&path));
            }
        }
    };

    // 1) Every directory on PATH.
    if let Some(path_var) = std::env::var_os("PATH") {
        for dir in std::env::split_paths(&path_var) {
            for bin in ENGINE_BINS {
                consider(dir.join(bin), &mut found);
            }
        }
    }

    // 2) Common fixed locations per OS.
    #[cfg(target_os = "windows")]
    let roots: Vec<std::path::PathBuf> = ["C:\\Program Files", "C:\\Program Files (x86)", "C:\\Games"]
        .iter()
        .flat_map(|r| ["GZDoom", "gzdoom", "Zandronum"].iter().map(move |s| std::path::Path::new(r).join(s)))
        .collect();
    #[cfg(not(target_os = "windows"))]
    let roots: Vec<std::path::PathBuf> = ["/usr/games", "/usr/bin", "/usr/local/bin", "/snap/bin"]
        .iter()
        .map(std::path::PathBuf::from)
        .collect();

    for root in roots {
        for bin in ENGINE_BINS {
            consider(root.join(bin), &mut found);
        }
    }

    Ok(found)
}

/// Validate a single user-picked executable path.
pub fn inspect_engine(exe: &str) -> AppResult<Engine> {
    let path = Path::new(exe);
    if !path.is_file() {
        return Err(crate::error::AppError::msg("Engine path is not a file"));
    }
    Ok(make_engine(path))
}
