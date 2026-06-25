use std::fs;
use std::path::Path;

use crate::models::{
    CompatReport, ConflictHit, ConflictRule, GraphEdge, GraphNode, ModGraph, Profile,
};

/// A small built-in seed of well-known GZDoom mod conflicts. Users can extend
/// this with `conflicts.json` in the app data dir.
fn builtin_rules() -> Vec<ConflictRule> {
    let r = |a: &str, b: &str, sev: &str, note: &str, patch: Option<&str>| ConflictRule {
        a: a.into(),
        b: b.into(),
        severity: sev.into(),
        note: note.into(),
        patch: patch.map(|s| s.into()),
    };
    vec![
        r(
            "brutal",
            "complex",
            "block",
            "Brutal Doom and Complex Doom replace the same actors and break each other.",
            None,
        ),
        r(
            "brutal",
            "project brutality",
            "block",
            "Two competing gameplay overhauls — load only one.",
            None,
        ),
        r(
            "smooth",
            "brutal",
            "warn",
            "Smooth Doom animations are overridden by Brutal Doom's own sprites.",
            None,
        ),
        r(
            "hideous",
            "brutal",
            "warn",
            "Both heavily modify monsters; expect missing/duplicated behaviour.",
            None,
        ),
        r(
            "lights.pk3",
            "brightmaps",
            "info",
            "Both touch dynamic lighting — order matters, generally harmless.",
            None,
        ),
    ]
}

/// Load rules: builtins plus any user-defined `conflicts.json` (array of rules).
pub fn load_rules(base: &Path) -> Vec<ConflictRule> {
    let mut rules = builtin_rules();
    let user = base.join("conflicts.json");
    if let Ok(text) = fs::read_to_string(&user) {
        if let Ok(extra) = serde_json::from_str::<Vec<ConflictRule>>(&text) {
            rules.extend(extra);
        }
    }
    rules
}

fn matches(name: &str, needle: &str) -> bool {
    name.to_lowercase().contains(&needle.to_lowercase())
}

/// Evaluate a profile against the conflict rules and return a compatibility
/// report. Score starts at 100 and is reduced per detected conflict by
/// severity (block -35, warn -12, info -3), floored at 0.
pub fn evaluate(base: &Path, profile: &Profile) -> CompatReport {
    let rules = load_rules(base);
    let enabled: Vec<&str> = profile
        .load_order
        .iter()
        .filter(|e| e.enabled)
        .map(|e| e.name.as_str())
        .collect();

    let mut hits = Vec::new();
    let mut score: i32 = 100;
    for rule in &rules {
        let has_a = enabled.iter().any(|n| matches(n, &rule.a));
        let has_b = enabled.iter().any(|n| matches(n, &rule.b));
        if has_a && has_b {
            score -= match rule.severity.as_str() {
                "block" => 35,
                "warn" => 12,
                _ => 3,
            };
            hits.push(ConflictHit {
                a: rule.a.clone(),
                b: rule.b.clone(),
                severity: rule.severity.clone(),
                note: rule.note.clone(),
                patch: rule.patch.clone(),
            });
        }
    }

    let mut warnings = Vec::new();
    if profile.iwad.is_none() {
        warnings.push("No IWAD selected — the build cannot launch.".into());
        score -= 20;
    }
    let gameplay = profile
        .load_order
        .iter()
        .filter(|e| e.enabled && e.group == crate::models::ModGroup::Gameplay)
        .count();
    if gameplay > 1 {
        warnings.push(format!(
            "{gameplay} gameplay mods enabled — these usually conflict; keep one."
        ));
        score -= (gameplay as i32 - 1) * 8;
    }

    CompatReport {
        score: score.clamp(0, 100) as u8,
        hits,
        warnings,
    }
}

/// Build a relationship graph: sequential load-order edges plus conflict edges.
pub fn graph(base: &Path, profile: &Profile) -> ModGraph {
    let nodes: Vec<GraphNode> = profile
        .load_order
        .iter()
        .map(|e| GraphNode {
            id: e.path.clone(),
            name: e.name.clone(),
            group: e.group,
        })
        .collect();

    let mut edges = Vec::new();
    let enabled: Vec<&crate::models::LoadEntry> =
        profile.load_order.iter().filter(|e| e.enabled).collect();
    for w in enabled.windows(2) {
        edges.push(GraphEdge {
            from: w[0].path.clone(),
            to: w[1].path.clone(),
            kind: "order".into(),
        });
    }

    let rules = load_rules(base);
    for rule in &rules {
        let a = enabled.iter().find(|e| matches(&e.name, &rule.a));
        let b = enabled.iter().find(|e| matches(&e.name, &rule.b));
        if let (Some(a), Some(b)) = (a, b) {
            edges.push(GraphEdge {
                from: a.path.clone(),
                to: b.path.clone(),
                kind: "conflict".into(),
            });
        }
    }

    ModGraph { nodes, edges }
}
