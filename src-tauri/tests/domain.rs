//! Integration tests for DoomForge's pure domain logic. These exercise the
//! library crate (`doom_forge_lib`) without Tauri or the network.

use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use doom_forge_lib::models::{LoadEntry, ModGroup, Profile};
use doom_forge_lib::{conflicts, launch, load_order, profile, scan};

fn entry(name: &str, group: ModGroup, enabled: bool) -> LoadEntry {
    LoadEntry {
        path: format!("/mods/{name}"),
        name: name.into(),
        group,
        enabled,
    }
}

fn profile_with(iwad: Option<&str>, load_order: Vec<LoadEntry>) -> Profile {
    Profile {
        id: "test".into(),
        name: "Test build".into(),
        description: String::new(),
        engine_path: None,
        iwad: iwad.map(|s| s.into()),
        load_order,
        extra_args: vec![],
        created_at: "2026-01-01T00:00:00Z".into(),
        updated_at: "2026-01-01T00:00:00Z".into(),
        last_played_at: None,
    }
}

fn unique_tmp() -> PathBuf {
    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
    let dir = std::env::temp_dir().join(format!("doomforge-test-{nanos}"));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

#[test]
fn load_priority_orders_maps_before_overrides() {
    assert!(ModGroup::Maps.load_priority() < ModGroup::Gameplay.load_priority());
    assert!(ModGroup::Gameplay.load_priority() < ModGroup::Audio.load_priority());
    assert!(ModGroup::Audio.load_priority() < ModGroup::Visuals.load_priority());
    assert!(ModGroup::Visuals.load_priority() < ModGroup::Patch.load_priority());
    assert!(ModGroup::Patch.load_priority() < ModGroup::Other.load_priority());
}

#[test]
fn auto_order_sorts_by_group_then_name() {
    let input = vec![
        entry("zpatch.pk3", ModGroup::Patch, true),
        entry("b_map.wad", ModGroup::Maps, true),
        entry("a_map.wad", ModGroup::Maps, true),
        entry("guns.pk3", ModGroup::Gameplay, true),
    ];
    let sorted = load_order::auto_order(&input);
    let names: Vec<&str> = sorted.iter().map(|e| e.name.as_str()).collect();
    // Maps first (alphabetical), then gameplay, then patch.
    assert_eq!(names, vec!["a_map.wad", "b_map.wad", "guns.pk3", "zpatch.pk3"]);
}

#[test]
fn build_args_requires_an_iwad() {
    let p = profile_with(None, vec![]);
    assert!(launch::build_args(&p, false).is_err());
}

#[test]
fn build_args_includes_iwad_and_enabled_files_only() {
    let p = profile_with(
        Some("doom2.wad"),
        vec![
            entry("a.pk3", ModGroup::Gameplay, true),
            entry("disabled.pk3", ModGroup::Visuals, false),
            entry("b.pk3", ModGroup::Visuals, true),
        ],
    );
    let args = launch::build_args(&p, false).unwrap();
    assert_eq!(args[0], "-iwad");
    assert_eq!(args[1], "doom2.wad");
    let file_pos = args.iter().position(|a| a == "-file").unwrap();
    let files = &args[file_pos + 1..];
    assert!(files.contains(&"/mods/a.pk3".to_string()));
    assert!(files.contains(&"/mods/b.pk3".to_string()));
    assert!(!files.contains(&"/mods/disabled.pk3".to_string()));
}

#[test]
fn build_args_safe_mode_disables_autoload() {
    let p = profile_with(Some("doom2.wad"), vec![]);
    let args = launch::build_args(&p, true).unwrap();
    assert!(args.contains(&"-noautoload".to_string()));
}

#[test]
fn evaluate_flags_known_blocking_conflict() {
    // Empty base dir => only the built-in rules apply (no user conflicts.json).
    let base = unique_tmp();
    let p = profile_with(
        Some("doom2.wad"),
        vec![
            entry("brutalv21.pk3", ModGroup::Other, true),
            entry("complexdoom.pk3", ModGroup::Other, true),
        ],
    );
    let report = conflicts::evaluate(&base, &p);
    assert_eq!(report.hits.len(), 1);
    assert_eq!(report.hits[0].severity, "block");
    assert!(report.score < 100, "blocking conflict should lower the score");
    std::fs::remove_dir_all(&base).ok();
}

#[test]
fn evaluate_warns_when_no_iwad() {
    let base = unique_tmp();
    let report = conflicts::evaluate(&base, &profile_with(None, vec![]));
    assert!(report.warnings.iter().any(|w| w.contains("IWAD")));
    std::fs::remove_dir_all(&base).ok();
}

#[test]
fn describe_paths_classifies_by_filename() {
    let paths = vec![
        "/x/Brutalv21.pk3".to_string(),
        "/x/SmoothDoom.pk3".to_string(),
        "/x/compat_patch.pk3".to_string(),
        "/x/notamod.txt".to_string(),
    ];
    let mods = scan::describe_paths(&paths);
    assert_eq!(mods.len(), 3, "the .txt should be skipped");
    let group = |name: &str| mods.iter().find(|m| m.name == name).map(|m| m.group);
    assert_eq!(group("Brutalv21.pk3"), Some(ModGroup::Gameplay));
    assert_eq!(group("SmoothDoom.pk3"), Some(ModGroup::Visuals));
    assert_eq!(group("compat_patch.pk3"), Some(ModGroup::Patch));
}

#[test]
fn profile_export_import_roundtrip_assigns_new_id() {
    let base = unique_tmp();
    let original = profile_with(
        Some("doom2.wad"),
        vec![entry("a.pk3", ModGroup::Gameplay, true)],
    );
    let saved = profile::save_profile(&base, original).unwrap();

    let dest = base.join("exported.dfprofile");
    profile::export_profile(&base, &saved.id, dest.to_str().unwrap()).unwrap();

    let imported = profile::import_profile(&base, dest.to_str().unwrap()).unwrap();
    assert_ne!(imported.id, saved.id, "import should mint a fresh id");
    assert_eq!(imported.name, saved.name);
    assert_eq!(imported.load_order.len(), 1);
    assert_eq!(imported.iwad.as_deref(), Some("doom2.wad"));

    std::fs::remove_dir_all(&base).ok();
}
