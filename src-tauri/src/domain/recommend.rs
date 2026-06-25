use crate::models::{ModFile, ModGroup, Profile, Recommendation};

/// Recommend mods from the scanned library that aren't already in the build.
///
/// Heuristic affinity: prefer filling under-represented groups (a build with
/// gameplay but no visuals gets visual suggestions), and boost mods whose tags
/// overlap with what's already in the profile.
pub fn recommend(library: &[ModFile], profile: &Profile, limit: usize) -> Vec<Recommendation> {
    let in_build: std::collections::HashSet<&str> =
        profile.load_order.iter().map(|e| e.path.as_str()).collect();

    let mut group_counts = std::collections::HashMap::<ModGroup, usize>::new();
    for e in &profile.load_order {
        *group_counts.entry(e.group).or_default() += 1;
    }
    let mut recs: Vec<Recommendation> = Vec::new();
    for m in library {
        if in_build.contains(m.path.as_str()) {
            continue;
        }
        let group_have = *group_counts.get(&m.group).unwrap_or(&0);
        // Higher score for groups the build lacks.
        let score = match group_have {
            0 => 1.0,
            1 => 0.5,
            _ => 0.15,
        };
        let reason = if group_have == 0 {
            format!("Adds {:?} content your build is missing", m.group)
        } else {
            format!("More {:?} content", m.group)
        };

        recs.push(Recommendation {
            path: m.path.clone(),
            name: m.name.clone(),
            group: m.group,
            reason,
            score,
        });
    }
    recs.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal));
    recs.truncate(limit);
    recs
}

/// "One button — forge me a meaty 2026 build". Assembles a sensible profile
/// from the library: one gameplay overhaul, a mapset, plus visuals & audio,
/// ordered correctly. Purely local heuristic (no AI required).
pub fn forge_build(library: &[ModFile], iwad: Option<String>) -> Profile {
    let pick = |g: ModGroup, n: usize| -> Vec<&ModFile> {
        let mut v: Vec<&ModFile> = library.iter().filter(|m| m.group == g).collect();
        // Prefer bigger files — usually the "main" content in each group.
        v.sort_by(|a, b| b.size.cmp(&a.size));
        v.into_iter().take(n).collect()
    };

    let mut chosen: Vec<&ModFile> = Vec::new();
    chosen.extend(pick(ModGroup::Maps, 1));
    chosen.extend(pick(ModGroup::Gameplay, 1));
    chosen.extend(pick(ModGroup::Audio, 1));
    chosen.extend(pick(ModGroup::Visuals, 2));

    let load_order: Vec<crate::models::LoadEntry> = chosen
        .iter()
        .map(|m| crate::models::LoadEntry {
            path: m.path.clone(),
            name: m.name.clone(),
            group: m.group,
            enabled: true,
        })
        .collect();
    let ordered = crate::load_order::auto_order(&load_order);

    let now = crate::profile::now_iso();
    Profile {
        id: uuid::Uuid::new_v4().to_string(),
        name: "Meaty 2026 build".into(),
        description: "Auto-forged: a gameplay overhaul + mapset + visuals & audio.".into(),
        engine_path: None,
        iwad,
        load_order: ordered,
        extra_args: Vec::new(),
        created_at: now.clone(),
        updated_at: now,
        last_played_at: None,
    }
}
