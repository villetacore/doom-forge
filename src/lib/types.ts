// Mirror of the Rust domain types (serde produces camelCase shapes).

export type ModGroup =
  | "gameplay"
  | "maps"
  | "visuals"
  | "audio"
  | "patch"
  | "other";

export interface ModFile {
  path: string;
  name: string;
  extension: string;
  size: number;
  sha256?: string;
  group: ModGroup;
  tags: string[];
}

export interface Engine {
  path: string;
  name: string;
  version?: string;
}

export interface Iwad {
  fileName: string;
  title: string;
  path?: string;
  present: boolean;
}

export interface LoadEntry {
  path: string;
  name: string;
  group: ModGroup;
  enabled: boolean;
}

export interface Profile {
  id: string;
  name: string;
  description: string;
  enginePath?: string;
  iwad?: string;
  loadOrder: LoadEntry[];
  extraArgs: string[];
  createdAt: string;
  updatedAt: string;
  lastPlayedAt?: string;
}

export interface DuplicateGroup {
  reason: string;
  files: string[];
}

export interface ConflictHit {
  a: string;
  b: string;
  severity: "block" | "warn" | "info";
  note: string;
  patch?: string;
}

export interface CompatReport {
  score: number;
  hits: ConflictHit[];
  warnings: string[];
}

export interface GraphNode {
  id: string;
  name: string;
  group: ModGroup;
}

export interface GraphEdge {
  from: string;
  to: string;
  kind: "order" | "conflict";
}

export interface ModGraph {
  nodes: GraphNode[];
  edges: GraphEdge[];
}

export interface SnapshotMeta {
  id: string;
  label: string;
  createdAt: string;
  entryCount: number;
}

export interface Stability {
  launches: number;
  crashes: number;
  rating: number;
}

export interface LogAnalysis {
  summary: string;
  suspectMods: string[];
  signals: string[];
}

export interface Recommendation {
  path: string;
  name: string;
  group: ModGroup;
  reason: string;
  score: number;
}

export interface ProfileDiff {
  onlyInA: string[];
  onlyInB: string[];
  common: string[];
  reordered: boolean;
}

export interface PackageEntry {
  id: string;
  name: string;
  description: string;
  version: string;
  url: string;
  tags: string[];
  homepage?: string;
}

export const GROUP_LABELS: Record<ModGroup, string> = {
  maps: "Maps",
  gameplay: "Gameplay",
  audio: "Audio",
  visuals: "Visuals",
  patch: "Patches",
  other: "Other",
};

export const GROUP_ORDER: ModGroup[] = [
  "maps",
  "gameplay",
  "audio",
  "visuals",
  "patch",
  "other",
];
