use std::path::Path;

use crate::models::Iwad;

/// Canonical IWAD filenames recognised by GZDoom and their display titles.
const KNOWN_IWADS: &[(&str, &str)] = &[
    ("doom.wad", "The Ultimate DOOM"),
    ("doom1.wad", "DOOM (Shareware)"),
    ("doom2.wad", "DOOM II: Hell on Earth"),
    ("plutonia.wad", "Final DOOM: The Plutonia Experiment"),
    ("tnt.wad", "Final DOOM: TNT Evilution"),
    ("heretic.wad", "Heretic"),
    ("hexen.wad", "Hexen"),
    ("hexdd.wad", "Hexen: Deathkings of the Dark Citadel"),
    ("strife1.wad", "Strife"),
    ("freedoom1.wad", "Freedoom: Phase 1"),
    ("freedoom2.wad", "Freedoom: Phase 2"),
    ("chex3.wad", "Chex Quest 3"),
];

/// Given a list of search directories, report which known IWADs are present.
pub fn check_iwads(dirs: &[String]) -> Vec<Iwad> {
    KNOWN_IWADS
        .iter()
        .map(|(file, title)| {
            let found = dirs.iter().find_map(|d| {
                let candidate = Path::new(d).join(file);
                if candidate.is_file() {
                    Some(candidate.to_string_lossy().to_string())
                } else {
                    // Case-insensitive fallback for filesystems that need it.
                    std::fs::read_dir(d).ok().and_then(|rd| {
                        rd.filter_map(|e| e.ok()).find_map(|e| {
                            if e.file_name().to_string_lossy().eq_ignore_ascii_case(file) {
                                Some(e.path().to_string_lossy().to_string())
                            } else {
                                None
                            }
                        })
                    })
                }
            });
            Iwad {
                file_name: (*file).to_string(),
                title: (*title).to_string(),
                present: found.is_some(),
                path: found,
            }
        })
        .collect()
}
