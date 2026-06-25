import { useEffect, useState } from "react";
import { api } from "./lib/api";
import { useStore } from "./store/store";
import { useT } from "./i18n";
import { applyTheme } from "./theme/themes";
import { Icon, type IconName } from "./components/Icon";
import Sidebar from "./features/shell/Sidebar";
import BuildView from "./features/build/BuildView";
import LibraryView from "./features/library/LibraryView";
import BrowseView from "./features/browse/BrowseView";
import CompareView from "./features/compare/CompareView";
import CrashView from "./features/crash/CrashView";
import StatusView from "./features/status/StatusView";
import SettingsView from "./features/settings/SettingsView";

export type Section =
  | "build"
  | "library"
  | "browse"
  | "compare"
  | "crash"
  | "status"
  | "settings";

const VIEWS: Record<Section, { view: () => JSX.Element; icon: IconName }> = {
  build: { view: BuildView, icon: "build" },
  library: { view: LibraryView, icon: "library" },
  browse: { view: BrowseView, icon: "browse" },
  compare: { view: CompareView, icon: "compare" },
  crash: { view: CrashView, icon: "crash" },
  status: { view: StatusView, icon: "status" },
  settings: { view: SettingsView, icon: "settings" },
};

const isSection = (s: string): s is Section => s in VIEWS;

export default function App() {
  const t = useT();
  const [section, setSectionState] = useState<Section>(() => {
    const h = typeof location !== "undefined" ? location.hash.replace("#", "") : "";
    return isSection(h) ? h : "build";
  });
  const { settings, mods, engines, iwads, setEngines, setIwads, setProfiles, toast } = useStore();

  // Navigation keeps the URL hash in sync — enables deep links and back/forward.
  const setSection = (s: Section) => {
    setSectionState(s);
    if (typeof location !== "undefined") location.hash = s;
  };
  useEffect(() => {
    const onHash = () => {
      const h = location.hash.replace("#", "");
      if (isSection(h)) setSectionState(h);
    };
    window.addEventListener("hashchange", onHash);
    return () => window.removeEventListener("hashchange", onHash);
  }, []);

  // Theme follows settings.
  useEffect(() => {
    applyTheme(settings.themeMode, settings.palette);
  }, [settings.themeMode, settings.palette]);

  // Keep the document language attribute in sync for a11y.
  useEffect(() => {
    document.documentElement.lang = settings.lang;
  }, [settings.lang]);

  // Startup: load saved builds and probe configured folders.
  useEffect(() => {
    api.listProfiles().then(setProfiles).catch(() => {});
  }, []);
  useEffect(() => {
    if (settings.engineDir) api.scanEngines(settings.engineDir).then(setEngines).catch(() => {});
    const dirs = settings.iwadDirs.filter(Boolean);
    if (dirs.length) api.checkIwads(dirs).then(setIwads).catch(() => {});
  }, [settings.engineDir, settings.iwadDirs]);

  const meta = VIEWS[section];
  const View = meta.view;
  const iwadsFound = iwads.filter((i) => i.present).length;
  const ready = engines.length > 0 && iwadsFound > 0;

  return (
    <div className="app">
      <Sidebar section={section} onNavigate={setSection} />
      <div className="content">
        <header className="topbar">
          <span className="tb-icon"><Icon name={meta.icon} size={22} /></span>
          <div className="tb-text">
            <h1>{t(`nav.${section}`)}</h1>
            <p className="tb-sub">{t(`sub.${section}`)}</p>
          </div>
          <div className="tb-stats">
            <Stat n={mods.length} label={t("sidebar.mods")} />
            <Stat n={engines.length} label={t("sidebar.engines")} />
            <Stat n={iwadsFound} label={t("sidebar.iwads")} />
          </div>
        </header>
        <main className="view">
          <View />
        </main>
        <footer className="statusbar">
          <span className="sb-item">
            <span className={"sb-dot " + (engines.length ? "ok" : "off")} />
            <b>{engines.length}</b> {t("sidebar.engines")}
          </span>
          <span className="sb-item">
            <span className={"sb-dot " + (iwadsFound ? "ok" : "off")} />
            <b>{iwadsFound}</b> {t("sidebar.iwads")}
          </span>
          <span className="sb-item">
            <span className={"sb-dot " + (mods.length ? "ok" : "")} />
            <b>{mods.length}</b> {t("sidebar.mods")}
          </span>
          <span className="sb-item">
            <span className={"sb-dot " + (ready ? "ok" : "off")} />
            {t(ready ? "status.ready" : "status.notReady")}
          </span>
          <span className="spacer" />
          <span className="sb-version">DoomForge v0.1.0</span>
        </footer>
      </div>
      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}

function Stat({ n, label }: { n: number; label: string }) {
  return (
    <div className={"stat-chip" + (n === 0 ? " zero" : "")}>
      <b>{n}</b>
      <span>{label}</span>
    </div>
  );
}
