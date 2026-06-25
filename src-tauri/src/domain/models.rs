use serde::{Deserialize, Serialize};

/// Logical grouping used both for UI sections and load-order heuristics.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ModGroup {
    Gameplay,
    Maps,
    Visuals,
    Audio,
    Patch,
    Other,
}

impl ModGroup {
    /// Lower value == loaded earlier. GZDoom resolves later files on top,
    /// so gameplay/maps come first and visual/audio/patch overrides come last.
    pub fn load_priority(self) -> u8 {
        match self {
            ModGroup::Maps => 0,
            ModGroup::Gameplay => 1,
            ModGroup::Audio => 2,
            ModGroup::Visuals => 3,
            ModGroup::Patch => 4,
            ModGroup::Other => 5,
        }
    }
}

/// A single moddable file discovered on disk (.pk3/.wad/.pk7/.zip/.deh ...).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ModFile {
    /// Absolute path; doubles as the stable identifier.
    pub path: String,
    pub name: String,
    pub extension: String,
    pub size: u64,
    /// SHA-256, used for duplicate detection. Computed lazily/optionally.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub sha256: Option<String>,
    pub group: ModGroup,
    #[serde(default)]
    pub tags: Vec<String>,
}

/// A detected source-port executable.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Engine {
    pub path: String,
    pub name: String,
    /// Parsed version string, e.g. "4.12.2". None if it couldn't be read.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub version: Option<String>,
}

/// An IWAD (commercial/freeware base game data) and whether it was found.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Iwad {
    /// Canonical filename, e.g. "doom2.wad".
    pub file_name: String,
    /// Human label, e.g. "DOOM II: Hell on Earth".
    pub title: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub path: Option<String>,
    pub present: bool,
}

/// An entry inside a profile's ordered load list.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LoadEntry {
    pub path: String,
    pub name: String,
    pub group: ModGroup,
    pub enabled: bool,
}

/// A saved build configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Profile {
    pub id: String,
    pub name: String,
    #[serde(default)]
    pub description: String,
    /// Path to the engine executable to use.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub engine_path: Option<String>,
    /// IWAD filename or absolute path.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub iwad: Option<String>,
    #[serde(default)]
    pub load_order: Vec<LoadEntry>,
    /// Extra raw command-line arguments.
    #[serde(default)]
    pub extra_args: Vec<String>,
    pub created_at: String,
    pub updated_at: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub last_played_at: Option<String>,
}

/// Two files that look like duplicates of each other.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DuplicateGroup {
    pub reason: String,
    pub files: Vec<String>,
}

/// A rule in the known-conflicts database. `a`/`b` are case-insensitive
/// substrings matched against mod filenames.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConflictRule {
    pub a: String,
    pub b: String,
    /// "block" | "warn" | "info".
    pub severity: String,
    pub note: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub patch: Option<String>,
}

/// A conflict detected within a concrete load order.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ConflictHit {
    pub a: String,
    pub b: String,
    pub severity: String,
    pub note: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub patch: Option<String>,
}

/// Result of evaluating a profile's compatibility.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CompatReport {
    /// 0..=100. 100 == no detected problems.
    pub score: u8,
    pub hits: Vec<ConflictHit>,
    pub warnings: Vec<String>,
}

/// A single edge in the mod dependency / relationship graph.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GraphEdge {
    pub from: String,
    pub to: String,
    /// "order" | "conflict".
    pub kind: String,
}

/// Graph nodes + edges for the dependency view.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModGraph {
    pub nodes: Vec<GraphNode>,
    pub edges: Vec<GraphEdge>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphNode {
    pub id: String,
    pub name: String,
    pub group: ModGroup,
}

/// Metadata for a saved profile snapshot.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotMeta {
    pub id: String,
    pub label: String,
    pub created_at: String,
    pub entry_count: usize,
}

/// Per-profile stability tracking.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Stability {
    pub launches: u32,
    pub crashes: u32,
    /// 0..=100; higher is more stable.
    pub rating: u8,
}

/// Result of analysing a GZDoom crash/log file.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct LogAnalysis {
    pub summary: String,
    /// Mod paths/names most likely responsible, best guess first.
    pub suspect_mods: Vec<String>,
    /// Notable lines/signals extracted from the log.
    pub signals: Vec<String>,
}

/// A recommended mod to add to a build.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Recommendation {
    pub path: String,
    pub name: String,
    pub group: ModGroup,
    pub reason: String,
    pub score: f32,
}

/// Diff between two profiles' load orders.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProfileDiff {
    pub only_in_a: Vec<String>,
    pub only_in_b: Vec<String>,
    pub common: Vec<String>,
    pub reordered: bool,
}
