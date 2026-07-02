use std::collections::HashSet;
use std::path::Path;

use crate::models::{Profile, ProfileDiff};

/// Diff two profiles' load orders.
pub fn diff(a: &Profile, b: &Profile) -> ProfileDiff {
    let set_a: HashSet<&str> = a.load_order.iter().map(|e| e.name.as_str()).collect();
    let set_b: HashSet<&str> = b.load_order.iter().map(|e| e.name.as_str()).collect();

    let only_in_a: Vec<String> = a
        .load_order
        .iter()
        .filter(|e| !set_b.contains(e.name.as_str()))
        .map(|e| e.name.clone())
        .collect();
    let only_in_b: Vec<String> = b
        .load_order
        .iter()
        .filter(|e| !set_a.contains(e.name.as_str()))
        .map(|e| e.name.clone())
        .collect();
    let common: Vec<String> = a
        .load_order
        .iter()
        .filter(|e| set_b.contains(e.name.as_str()))
        .map(|e| e.name.clone())
        .collect();

    // Reordered if the relative order of shared entries differs.
    let order_a: Vec<&str> = a
        .load_order
        .iter()
        .map(|e| e.name.as_str())
        .filter(|n| set_b.contains(n))
        .collect();
    let order_b: Vec<&str> = b
        .load_order
        .iter()
        .map(|e| e.name.as_str())
        .filter(|n| set_a.contains(n))
        .collect();

    ProfileDiff {
        only_in_a,
        only_in_b,
        common,
        reordered: order_a != order_b,
    }
}

/// Build a Markdown problem report for a profile: config, load order,
/// compatibility findings, and stability stats. Used by "Generate report".
pub fn problem_report(base: &Path, profile: &Profile) -> String {
    let compat = crate::conflicts::evaluate(base, profile);
    let stab = crate::stability::get(base, &profile.id);

    let mut s = String::new();
    s.push_str(&format!("# DoomForge problem report — {}\n\n", profile.name));
    s.push_str(&format!("- Engine: {}\n", profile.engine_path.clone().unwrap_or("(auto)".into())));
    s.push_str(&format!("- IWAD: {}\n", profile.iwad.clone().unwrap_or("(none)".into())));
    s.push_str(&format!("- Compatibility score: {}%\n", compat.score));
    s.push_str(&format!(
        "- Stability: {}% ({} launches, {} crashes)\n\n",
        stab.rating, stab.launches, stab.crashes
    ));

    s.push_str("## Load order\n\n");
    for (i, e) in profile.load_order.iter().enumerate() {
        s.push_str(&format!(
            "{}. {} [{:?}]{}\n",
            i + 1,
            e.name,
            e.group,
            if e.enabled { "" } else { " (disabled)" }
        ));
    }

    if !compat.hits.is_empty() {
        s.push_str("\n## Detected conflicts\n\n");
        for h in &compat.hits {
            s.push_str(&format!("- **[{}]** {} ↔ {}: {}\n", h.severity, h.a, h.b, h.note));
        }
    }
    if !compat.warnings.is_empty() {
        s.push_str("\n## Warnings\n\n");
        for w in &compat.warnings {
            s.push_str(&format!("- {w}\n"));
        }
    }
    if !profile.extra_args.is_empty() {
        s.push_str(&format!("\n## Extra args\n\n`{}`\n", profile.extra_args.join(" ")));
    }
    s
}
