//! `doom` — a Cargo-style package manager / runner for GZDoom mods, built on
//! the DoomForge core. Operates on a local `doomforge.build.json` in the CWD.
//!
//! Examples:
//!   doom registry https://example.com/registry.json
//!   doom search brutal
//!   doom add brutal-doom
//!   doom add eviternity
//!   doom list
//!   doom run            # launches the current build

use std::fs;
use std::path::Path;
use std::process::exit;

use doom_forge_lib::models::{LoadEntry, Profile};
use doom_forge_lib::{launch, load_order, net, profile, scan};
use serde::{Deserialize, Serialize};

const BUILD_FILE: &str = "doomforge.build.json";

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct BuildFile {
    #[serde(default)]
    registry: String,
    #[serde(default)]
    mods_dir: String,
    #[serde(default)]
    engine: Option<String>,
    profile: Profile,
}

impl Default for BuildFile {
    fn default() -> Self {
        let now = profile::now_iso();
        BuildFile {
            registry: String::new(),
            mods_dir: "mods".into(),
            engine: None,
            profile: Profile {
                id: uuid::Uuid::new_v4().to_string(),
                name: "cli-build".into(),
                description: String::new(),
                engine_path: None,
                iwad: None,
                load_order: Vec::new(),
                extra_args: Vec::new(),
                created_at: now.clone(),
                updated_at: now,
                last_played_at: None,
            },
        }
    }
}

fn load() -> BuildFile {
    fs::read_to_string(BUILD_FILE)
        .ok()
        .and_then(|t| serde_json::from_str(&t).ok())
        .unwrap_or_default()
}

fn store(b: &BuildFile) {
    let _ = fs::write(BUILD_FILE, serde_json::to_string_pretty(b).unwrap());
}

fn die(msg: impl AsRef<str>) -> ! {
    eprintln!("error: {}", msg.as_ref());
    exit(1);
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let cmd = args.first().map(|s| s.as_str()).unwrap_or("help");
    let rest = &args[1.min(args.len())..];

    match cmd {
        "init" => {
            store(&BuildFile::default());
            println!("Created {BUILD_FILE}");
        }
        "registry" => {
            let url = rest.first().unwrap_or_else(|| die("usage: doom registry <url|path>"));
            let mut b = load();
            b.registry = url.clone();
            store(&b);
            println!("Registry set to {url}");
        }
        "search" => {
            let q = rest.join(" ");
            let b = load();
            if b.registry.is_empty() {
                die("no registry set — run `doom registry <url>` first");
            }
            match net::search_registry(&b.registry, &q) {
                Ok(pkgs) => {
                    if pkgs.is_empty() {
                        println!("No packages match \"{q}\".");
                    }
                    for p in pkgs {
                        println!("{:20} {:10} {}", p.id, p.version, p.name);
                    }
                }
                Err(e) => die(e.to_string()),
            }
        }
        "add" => {
            let id = rest.first().unwrap_or_else(|| die("usage: doom add <package-id>"));
            let mut b = load();
            if b.registry.is_empty() {
                die("no registry set — run `doom registry <url>` first");
            }
            match net::install_package(&b.registry, id, &b.mods_dir) {
                Ok(path) => {
                    // Reuse the scanner to classify the freshly installed file.
                    let group = scan::scan_dir(&b.mods_dir, false)
                        .ok()
                        .and_then(|files| files.into_iter().find(|f| f.path == path))
                        .map(|f| f.group)
                        .unwrap_or(doom_forge_lib::models::ModGroup::Other);
                    let name = Path::new(&path)
                        .file_name()
                        .map(|n| n.to_string_lossy().to_string())
                        .unwrap_or_else(|| id.clone());
                    if !b.profile.load_order.iter().any(|e| e.path == path) {
                        b.profile.load_order.push(LoadEntry {
                            path,
                            name: name.clone(),
                            group,
                            enabled: true,
                        });
                    }
                    b.profile.load_order = load_order::auto_order(&b.profile.load_order);
                    store(&b);
                    println!("Added {name}");
                }
                Err(e) => die(e.to_string()),
            }
        }
        "remove" | "rm" => {
            let needle = rest.first().unwrap_or_else(|| die("usage: doom remove <name>"));
            let mut b = load();
            let before = b.profile.load_order.len();
            b.profile
                .load_order
                .retain(|e| !e.name.to_lowercase().contains(&needle.to_lowercase()));
            store(&b);
            println!("Removed {} entr(ies)", before - b.profile.load_order.len());
        }
        "list" | "ls" => {
            let b = load();
            if b.profile.load_order.is_empty() {
                println!("(empty build)");
            }
            for (i, e) in b.profile.load_order.iter().enumerate() {
                println!("{:>2}. [{:?}] {}", i + 1, e.group, e.name);
            }
        }
        "iwad" => {
            let iwad = rest.first().unwrap_or_else(|| die("usage: doom iwad <path>"));
            let mut b = load();
            b.profile.iwad = Some(iwad.clone());
            store(&b);
            println!("IWAD set to {iwad}");
        }
        "engine" => {
            let eng = rest.first().unwrap_or_else(|| die("usage: doom engine <path>"));
            let mut b = load();
            b.engine = Some(eng.clone());
            store(&b);
            println!("Engine set to {eng}");
        }
        "fetch-freedoom" => {
            let dir = rest.first().cloned().unwrap_or_else(|| "iwads".into());
            match net::install_freedoom(&dir) {
                Ok(wads) => {
                    for w in &wads {
                        println!("installed {w}");
                    }
                }
                Err(e) => die(e.to_string()),
            }
        }
        "get" => {
            let url = rest.first().unwrap_or_else(|| die("usage: doom get <url> [dir]"));
            let b = load();
            let dir = rest.get(1).cloned().unwrap_or(b.mods_dir.clone());
            match net::download_mod(url, &dir) {
                Ok(msg) => println!("{msg}"),
                Err(e) => die(e.to_string()),
            }
        }
        "run" => {
            let b = load();
            let engine = b
                .engine
                .clone()
                .unwrap_or_else(|| die("no engine set — run `doom engine <path>`"));
            let safe = rest.iter().any(|a| a == "--safe");
            match launch::launch(&engine, &b.profile, safe) {
                Ok(cmd) => println!("launched: {cmd}"),
                Err(e) => die(e.to_string()),
            }
        }
        _ => {
            println!(
                "doom — GZDoom package manager\n\n\
                 Commands:\n\
                 \x20 init                 create {BUILD_FILE}\n\
                 \x20 registry <url|path>  set the package registry\n\
                 \x20 search <query>       search the registry\n\
                 \x20 add <id>             install a package and add to the build\n\
                 \x20 remove <name>        remove from the build\n\
                 \x20 list                 show the current load order\n\
                 \x20 iwad <path>          set the IWAD\n\
                 \x20 engine <path>        set the engine executable\n\
                 \x20 run [--safe]         launch the build"
            );
        }
    }
}
