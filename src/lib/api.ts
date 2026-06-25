import { invoke } from "@tauri-apps/api/core";
import type {
  CompatReport,
  DuplicateGroup,
  Engine,
  Iwad,
  LoadEntry,
  LogAnalysis,
  ModFile,
  ModGraph,
  PackageEntry,
  Profile,
  ProfileDiff,
  Recommendation,
  SnapshotMeta,
  Stability,
} from "./types";

// Typed wrappers over the Rust `#[tauri::command]` handlers.
export const api = {
  // library
  scanMods: (dir: string, withHashes: boolean) =>
    invoke<ModFile[]>("scan_mods", { dir, withHashes }),
  describeFiles: (paths: string[]) =>
    invoke<ModFile[]>("describe_files", { paths }),
  findDuplicates: (files: ModFile[]) =>
    invoke<DuplicateGroup[]>("find_duplicates", { files }),
  searchModContents: (files: ModFile[], query: string) =>
    invoke<string[]>("search_mod_contents", { files, query }),

  // engines / iwads
  scanEngines: (dir: string) => invoke<Engine[]>("scan_engines", { dir }),
  inspectEngine: (path: string) => invoke<Engine>("inspect_engine", { path }),
  detectEngines: () => invoke<Engine[]>("detect_engines"),
  checkIwads: (dirs: string[]) => invoke<Iwad[]>("check_iwads", { dirs }),

  // profiles
  autoOrder: (entries: LoadEntry[]) =>
    invoke<LoadEntry[]>("auto_order", { entries }),
  listProfiles: () => invoke<Profile[]>("list_profiles"),
  saveProfile: (profile: Profile) => invoke<Profile>("save_profile", { profile }),
  deleteProfile: (id: string) => invoke<void>("delete_profile", { id }),
  exportProfile: (id: string, dest: string) =>
    invoke<void>("export_profile", { id, dest }),
  importProfile: (src: string) => invoke<Profile>("import_profile", { src }),
  compareProfiles: (a: Profile, b: Profile) =>
    invoke<ProfileDiff>("compare_profiles", { a, b }),

  // builds
  launchProfile: (engine: string, profile: Profile, safeMode: boolean) =>
    invoke<string>("launch_profile", { engine, profile, safeMode }),
  dryRunProfile: (engine: string, profile: Profile) =>
    invoke<string>("dry_run_profile", { engine, profile }),
  evaluateCompat: (profile: Profile) =>
    invoke<CompatReport>("evaluate_compat", { profile }),
  modGraph: (profile: Profile) => invoke<ModGraph>("mod_graph", { profile }),
  createSnapshot: (profile: Profile, label: string) =>
    invoke<SnapshotMeta>("create_snapshot", { profile, label }),
  listSnapshots: (profileId: string) =>
    invoke<SnapshotMeta[]>("list_snapshots", { profileId }),
  restoreSnapshot: (profileId: string, snapshotId: string) =>
    invoke<Profile>("restore_snapshot", { profileId, snapshotId }),
  deleteSnapshot: (profileId: string, snapshotId: string) =>
    invoke<void>("delete_snapshot", { profileId, snapshotId }),
  recordOutcome: (profileId: string, crashed: boolean) =>
    invoke<Stability>("record_outcome", { profileId, crashed }),
  getStability: (profileId: string) =>
    invoke<Stability>("get_stability", { profileId }),
  recommendMods: (library: ModFile[], profile: Profile, limit: number) =>
    invoke<Recommendation[]>("recommend_mods", { library, profile, limit }),
  forgeBuild: (library: ModFile[], iwad?: string) =>
    invoke<Profile>("forge_build", { library, iwad }),
  generateReport: (profile: Profile) =>
    invoke<string>("generate_report", { profile }),
  saveText: (dest: string, contents: string) =>
    invoke<void>("save_text", { dest, contents }),

  // analysis
  analyzeLogFile: (path: string, profile: Profile) =>
    invoke<LogAnalysis>("analyze_log_file", { path, profile }),
  analyzeLogText: (text: string, profile: Profile) =>
    invoke<LogAnalysis>("analyze_log_text", { text, profile }),

  // network
  catalog: () => invoke<PackageEntry[]>("catalog"),
  installCatalog: (url: string, modsDir: string) =>
    invoke<string>("install_catalog", { url, modsDir }),
  searchRegistry: (source: string, query: string) =>
    invoke<PackageEntry[]>("search_registry", { source, query }),
  installPackage: (source: string, id: string, modsDir: string) =>
    invoke<string>("install_package", { source, id, modsDir }),
  importByUrl: (url: string, destDir: string) =>
    invoke<string>("import_by_url", { url, destDir }),
  installFreedoom: (iwadDir: string) =>
    invoke<string[]>("install_freedoom", { iwadDir }),
  installGzdoom: (destDir: string) =>
    invoke<string>("install_gzdoom", { destDir }),
  idgamesSearch: (query: string) =>
    invoke<PackageEntry[]>("idgames_search", { query }),

  // ai
  aiAnalyzeLog: (apiKey: string, model: string, log: string, loadOrder: string[]) =>
    invoke<string>("ai_analyze_log", { apiKey, model, log, loadOrder }),
  aiDescribeBuild: (apiKey: string, model: string, mods: string[]) =>
    invoke<string>("ai_describe_build", { apiKey, model, mods }),
};
