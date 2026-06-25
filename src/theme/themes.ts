// Theme system: a set of base modes (neutral scales) plus swappable accent
// palettes ("color schemes"), applied by writing CSS custom properties onto
// <html>. Modes control the background/text neutrals; palettes control accents.

export type ThemeMode = "dark" | "light" | "amoled";
export type PaletteId =
  | "ember"
  | "plasma"
  | "toxic"
  | "abyss"
  | "blood"
  | "gold"
  | "cobalt"
  | "viridian"
  | "magenta"
  | "slate";

export const THEME_MODES: ThemeMode[] = ["dark", "light", "amoled"];

export const PALETTES: { id: PaletteId; label: string; accent: string; accent2: string }[] = [
  { id: "ember", label: "Ember", accent: "#e2603a", accent2: "#f0a23a" },
  { id: "plasma", label: "Plasma", accent: "#9b6cff", accent2: "#c08bff" },
  { id: "toxic", label: "Toxic", accent: "#4caf50", accent2: "#9ae66e" },
  { id: "abyss", label: "Abyss", accent: "#3a8ee2", accent2: "#4cc7e0" },
  { id: "blood", label: "Blood", accent: "#d23f3f", accent2: "#f0653a" },
  { id: "gold", label: "Gold", accent: "#d9a227", accent2: "#f2d24b" },
  { id: "cobalt", label: "Cobalt", accent: "#4666e0", accent2: "#6f9bff" },
  { id: "viridian", label: "Viridian", accent: "#1fae8e", accent2: "#54e0c0" },
  { id: "magenta", label: "Magenta", accent: "#d6359b", accent2: "#ff6fc7" },
  { id: "slate", label: "Slate", accent: "#6c7a92", accent2: "#9fb0c8" },
];

const NEUTRALS: Record<ThemeMode, Record<string, string>> = {
  dark: {
    "--bg": "#0e0d0c",
    "--bg-2": "#16140f",
    "--surface": "#1b1814",
    "--surface-2": "#231f19",
    "--line": "#322a20",
    "--fg": "#ece4d8",
    "--fg-dim": "#b6aa99",
    "--muted": "#897c6a",
    "--ok": "#5fbf6a",
    "--err": "#e2564f",
    "--shadow": "rgba(0,0,0,0.45)",
  },
  light: {
    "--bg": "#f2efe9",
    "--bg-2": "#e9e4da",
    "--surface": "#ffffff",
    "--surface-2": "#f4f0e8",
    "--line": "#d8cfbf",
    "--fg": "#241f18",
    "--fg-dim": "#4a4234",
    "--muted": "#7c715f",
    "--ok": "#3f9d4a",
    "--err": "#c63b35",
    "--shadow": "rgba(60,45,25,0.15)",
  },
  amoled: {
    "--bg": "#000000",
    "--bg-2": "#080807",
    "--surface": "#0f0e0c",
    "--surface-2": "#161513",
    "--line": "#26221c",
    "--fg": "#f2ece2",
    "--fg-dim": "#bcb1a0",
    "--muted": "#7e7361",
    "--ok": "#5fbf6a",
    "--err": "#e2564f",
    "--shadow": "rgba(0,0,0,0.7)",
  },
};

function hexToRgb(hex: string): [number, number, number] {
  const h = hex.replace("#", "");
  return [
    parseInt(h.slice(0, 2), 16),
    parseInt(h.slice(2, 4), 16),
    parseInt(h.slice(4, 6), 16),
  ];
}

export function applyTheme(mode: ThemeMode, paletteId: PaletteId) {
  const root = document.documentElement;
  const neutrals = NEUTRALS[mode] ?? NEUTRALS.dark;
  for (const [k, v] of Object.entries(neutrals)) root.style.setProperty(k, v);

  const palette = PALETTES.find((p) => p.id === paletteId) ?? PALETTES[0];
  root.style.setProperty("--accent", palette.accent);
  root.style.setProperty("--accent-2", palette.accent2);
  const [r, g, b] = hexToRgb(palette.accent);
  root.style.setProperty("--accent-soft", `rgba(${r},${g},${b},0.16)`);
  root.style.setProperty("--accent-line", `rgba(${r},${g},${b},0.4)`);
  // Data attributes let CSS target a specific mode/palette when needed.
  root.setAttribute("data-theme", mode === "light" ? "light" : "dark");
  root.setAttribute("data-mode", mode);
  root.setAttribute("data-palette", paletteId);
}
