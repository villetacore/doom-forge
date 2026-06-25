use crate::models::LoadEntry;

/// Produce a recommended load order from a set of entries.
///
/// Heuristic: order by `ModGroup::load_priority` (maps & gameplay first,
/// visual/audio/patch overrides last) and break ties alphabetically. This is a
/// sane default for GZDoom, where files listed later override earlier ones.
pub fn auto_order(entries: &[LoadEntry]) -> Vec<LoadEntry> {
    let mut sorted: Vec<LoadEntry> = entries.to_vec();
    sorted.sort_by(|a, b| {
        a.group
            .load_priority()
            .cmp(&b.group.load_priority())
            .then_with(|| a.name.to_lowercase().cmp(&b.name.to_lowercase()))
    });
    sorted
}
