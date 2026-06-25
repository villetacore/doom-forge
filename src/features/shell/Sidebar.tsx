import { open } from "@tauri-apps/plugin-dialog";
import { api } from "../../lib/api";
import { useStore } from "../../store/store";
import { useT } from "../../i18n";
import { Icon, type IconName } from "../../components/Icon";
import { BrandMark } from "../../components/art";
import type { Section } from "../../App";
import type { Profile } from "../../lib/types";

const NAV: { id: Section; icon: IconName }[] = [
  { id: "build", icon: "build" },
  { id: "library", icon: "library" },
  { id: "browse", icon: "browse" },
  { id: "compare", icon: "compare" },
  { id: "crash", icon: "crash" },
  { id: "status", icon: "status" },
  { id: "settings", icon: "settings" },
];

function newProfile(name: string): Profile {
  const now = new Date().toISOString();
  return {
    id: crypto.randomUUID(),
    name,
    description: "",
    loadOrder: [],
    extraArgs: [],
    createdAt: now,
    updatedAt: now,
  };
}

export default function Sidebar({
  section,
  onNavigate,
}: {
  section: Section;
  onNavigate: (s: Section) => void;
}) {
  const t = useT();
  const {
    settings,
    setSettings,
    mods,
    setMods,
    setEngines,
    iwads,
    setIwads,
    profiles,
    setProfiles,
    activeProfileId,
    setActiveProfileId,
    setToast,
  } = useStore();

  async function pickDir(key: "modsDir" | "engineDir") {
    const dir = await open({ directory: true, multiple: false });
    if (typeof dir === "string") setSettings({ [key]: dir } as never);
  }
  async function addIwadDir() {
    const dir = await open({ directory: true, multiple: false });
    if (typeof dir === "string") setSettings({ iwadDirs: [...settings.iwadDirs, dir] });
  }

  async function rescan() {
    try {
      if (settings.modsDir) setMods(await api.scanMods(settings.modsDir, true));
      if (settings.engineDir) setEngines(await api.scanEngines(settings.engineDir));
      const dirs = settings.iwadDirs.filter(Boolean);
      if (dirs.length) setIwads(await api.checkIwads(dirs));
      setToast("OK");
    } catch (e) {
      setToast(String(e));
    }
  }

  async function create() {
    const p = await api.saveProfile(newProfile(t("sidebar.newBuild")));
    setProfiles([p, ...profiles]);
    setActiveProfileId(p.id);
    onNavigate("build");
  }

  async function forge() {
    if (mods.length === 0) return setToast(t("library.empty"));
    const iwad = iwads.find((i) => i.present);
    const p = await api.forgeBuild(mods, iwad?.path ?? iwad?.fileName);
    setProfiles([p, ...profiles]);
    setActiveProfileId(p.id);
    onNavigate("build");
  }

  return (
    <aside className="sidebar">
      <div className="brand">
        <BrandMark size={36} />
        <div className="brand-text">
          <div className="word"><b>DOOM</b><span>FORGE</span></div>
          <div className="tagline">{t("brand.tagline")}</div>
        </div>
      </div>

      <nav className="nav">
        {NAV.map((n) => (
          <button
            key={n.id}
            className={"nav-item" + (section === n.id ? " active" : "")}
            onClick={() => onNavigate(n.id)}
          >
            <Icon name={n.icon} className="ico" />
            {t(`nav.${n.id}`)}
          </button>
        ))}
      </nav>

      <section className="side-sec grow">
        <h4>
          {t("sidebar.profiles")}
          <span className="spacer" />
          <button className="icon-btn" title={t("sidebar.newBuild")} onClick={create}>
            <Icon name="plus" size={16} />
          </button>
        </h4>
        <div className="builds">
          {profiles.length === 0 && <p className="empty">{t("sidebar.noBuilds")}</p>}
          {profiles.map((p) => (
            <button
              key={p.id}
              className={"build-item" + (p.id === activeProfileId ? " active" : "")}
              onClick={() => {
                setActiveProfileId(p.id);
                onNavigate("build");
              }}
            >
              <span>{p.name}</span>
              <span className="count">{p.loadOrder.length}</span>
            </button>
          ))}
        </div>
      </section>

      <section className="side-sec">
        <h4>{t("sidebar.paths")}</h4>
        <FolderRow label={t("sidebar.mods")} value={settings.modsDir} onPick={() => pickDir("modsDir")} t={t} />
        <FolderRow label={t("sidebar.engines")} value={settings.engineDir} onPick={() => pickDir("engineDir")} t={t} />
        <div className="folder-row">
          <span>{t("sidebar.iwads")}</span>
          <button className="btn sm ghost" onClick={addIwadDir}>{t("sidebar.addDir")}</button>
        </div>
        {settings.iwadDirs.map((d, i) => (
          <div className="folder-val" key={i} title={d}>
            <span style={{ flex: 1 }}>{d}</span>
            <button
              className="icon-btn"
              onClick={() => setSettings({ iwadDirs: settings.iwadDirs.filter((_, j) => j !== i) })}
            >
              <Icon name="trash" size={13} />
            </button>
          </div>
        ))}
        <div className="btn-row" style={{ marginTop: 10 }}>
          <button className="btn sm" onClick={rescan}><Icon name="refresh" size={15} /> {t("sidebar.rescan")}</button>
          <button className="btn sm" onClick={forge}><Icon name="spark" size={15} /> {t("sidebar.forge")}</button>
        </div>
      </section>
    </aside>
  );
}

function FolderRow({
  label,
  value,
  onPick,
  t,
}: {
  label: string;
  value: string;
  onPick: () => void;
  t: (k: string) => string;
}) {
  return (
    <>
      <div className="folder-row">
        <span>{label}</span>
        <button className="btn sm ghost" onClick={onPick}>{t("common.browse")}</button>
      </div>
      <div className="folder-val" title={value}>
        {value || <span className="muted">{t("common.notSet")}</span>}
      </div>
    </>
  );
}
