import { create } from "zustand";
import type { Engine, Iwad, ModFile, Profile } from "../lib/types";
import type { Lang } from "../i18n";
import type { PaletteId, ThemeMode } from "../theme/themes";

interface Settings {
  modsDir: string;
  engineDir: string;
  iwadDirs: string[];
  registry: string;
  aiKey: string;
  aiModel: string;
  lang: Lang;
  themeMode: ThemeMode;
  palette: PaletteId;
}

const DEFAULTS: Settings = {
  modsDir: "",
  engineDir: "",
  iwadDirs: [],
  registry: "",
  aiKey: "",
  aiModel: "claude-opus-4-8",
  lang: "en",
  themeMode: "dark",
  palette: "ember",
};

const SETTINGS_KEY = "doomforge.settings";

function loadSettings(): Settings {
  try {
    const raw = localStorage.getItem(SETTINGS_KEY);
    if (raw) return { ...DEFAULTS, ...(JSON.parse(raw) as Partial<Settings>) };
  } catch {
    /* ignore */
  }
  return DEFAULTS;
}

interface AppState {
  settings: Settings;
  setSettings: (patch: Partial<Settings>) => void;

  mods: ModFile[];
  setMods: (mods: ModFile[]) => void;
  engines: Engine[];
  setEngines: (engines: Engine[]) => void;
  iwads: Iwad[];
  setIwads: (iwads: Iwad[]) => void;
  profiles: Profile[];
  setProfiles: (profiles: Profile[]) => void;
  activeProfileId: string | null;
  setActiveProfileId: (id: string | null) => void;

  toast: string | null;
  setToast: (msg: string | null) => void;
}

export const useStore = create<AppState>((set, get) => ({
  settings: loadSettings(),
  setSettings: (patch) => {
    const next = { ...get().settings, ...patch };
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(next));
    set({ settings: next });
  },

  mods: [],
  setMods: (mods) => set({ mods }),
  engines: [],
  setEngines: (engines) => set({ engines }),
  iwads: [],
  setIwads: (iwads) => set({ iwads }),
  profiles: [],
  setProfiles: (profiles) => set({ profiles }),
  activeProfileId: null,
  setActiveProfileId: (activeProfileId) => set({ activeProfileId }),

  toast: null,
  setToast: (toast) => {
    set({ toast });
    if (toast) setTimeout(() => set({ toast: null }), 4000);
  },
}));
