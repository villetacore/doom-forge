import { useMemo, useState } from "react";
import { open, save } from "@tauri-apps/plugin-dialog";
import { api } from "../../lib/api";
import { useStore } from "../../store/store";
import { useT } from "../../i18n";
import { Icon } from "../../components/Icon";
import { EmptyHero } from "../../components/EmptyHero";
import type { Engine, Profile, Recommendation } from "../../lib/types";
import LoadOrderEditor from "./LoadOrderEditor";
import CompatBar from "./CompatBar";
import SnapshotsPanel from "./SnapshotsPanel";
import DependencyGraph from "./DependencyGraph";

export default function BuildView() {
  const t = useT();
  const { profiles, setProfiles, activeProfileId, setActiveProfileId, engines, setEngines, iwads, mods, settings, setToast } =
    useStore();

  async function createBuild() {
    const now = new Date().toISOString();
    const fresh: Profile = {
      id: crypto.randomUUID(),
      name: t("sidebar.newBuild"),
      description: "",
      loadOrder: [],
      extraArgs: [],
      createdAt: now,
      updatedAt: now,
    };
    try {
      const saved = await api.saveProfile(fresh);
      setProfiles([saved, ...profiles]);
      setActiveProfileId(saved.id);
    } catch (e) { setToast(String(e)); }
  }
  const [cmd, setCmd] = useState<string | null>(null);
  const [showGraph, setShowGraph] = useState(false);
  const [recs, setRecs] = useState<Recommendation[] | null>(null);
  const [report, setReport] = useState<string | null>(null);

  const profile = useMemo(
    () => profiles.find((p) => p.id === activeProfileId) ?? null,
    [profiles, activeProfileId]
  );

  if (!profile)
    return (
      <EmptyHero art="helmet" title={t("build.emptyTitle")} hint={t("build.empty")}>
        <button className="btn primary lg" onClick={createBuild}>
          <Icon name="plus" /> {t("build.emptyCta")}
        </button>
      </EmptyHero>
    );

  const patch = (u: Partial<Profile>) => {
    const next = { ...profile, ...u };
    setProfiles(profiles.map((p) => (p.id === next.id ? next : p)));
  };

  async function persist() {
    try {
      const saved = await api.saveProfile(profile!);
      setProfiles(profiles.map((p) => (p.id === saved.id ? saved : p)));
      setToast("OK");
    } catch (e) { setToast(String(e)); }
  }

  async function remove() {
    await api.deleteProfile(profile!.id);
    setProfiles(profiles.filter((p) => p.id !== profile!.id));
    setActiveProfileId(null);
  }

  async function addFiles() {
    const picked = await open({
      multiple: true,
      filters: [{ name: "Doom mods", extensions: ["pk3", "pk7", "wad", "zip", "pke", "ipk3", "deh", "bex"] }],
    });
    const paths = Array.isArray(picked) ? picked : picked ? [picked] : [];
    if (paths.length === 0) return;
    const described = await api.describeFiles(paths as string[]);
    const existing = new Set(profile!.loadOrder.map((e) => e.path));
    const added = described
      .filter((m) => !existing.has(m.path))
      .map((m) => ({ path: m.path, name: m.name, group: m.group, enabled: true }));
    patch({ loadOrder: [...profile!.loadOrder, ...added] });
    setToast(`+${added.length}`);
  }

  async function pickEngineFile() {
    const f = await open({ multiple: false });
    if (typeof f !== "string") return;
    try {
      const eng: Engine = await api.inspectEngine(f);
      if (!engines.some((e) => e.path === eng.path)) setEngines([...engines, eng]);
      patch({ enginePath: eng.path });
    } catch (e) { setToast(String(e)); }
  }

  async function pickIwadFile() {
    const f = await open({ multiple: false, filters: [{ name: "IWAD", extensions: ["wad", "ipk3", "pk3"] }] });
    if (typeof f === "string") patch({ iwad: f });
  }

  async function autoSort() {
    patch({ loadOrder: await api.autoOrder(profile!.loadOrder) });
  }

  async function exportBuild() {
    const dest = await save({ defaultPath: `${profile!.name}.dfprofile`, filters: [{ name: "DoomForge", extensions: ["dfprofile"] }] });
    if (dest) { await api.saveProfile(profile!); await api.exportProfile(profile!.id, dest); setToast("OK"); }
  }

  async function launch(safe: boolean) {
    const engine = profile!.enginePath || engines[0]?.path;
    if (!engine) return setToast(t("status.noEngines"));
    try { await api.saveProfile(profile!); setCmd(await api.launchProfile(engine, profile!, safe)); }
    catch (e) { setToast(String(e)); }
  }

  async function autotest() {
    const engine = profile!.enginePath || engines[0]?.path;
    if (!engine) return setToast(t("status.noEngines"));
    try { setCmd(await api.dryRunProfile(engine, profile!)); setToast("OK"); }
    catch (e) { setToast(String(e)); }
  }

  async function recommend() { setRecs(await api.recommendMods(mods, profile!, 8)); }
  function addRec(r: Recommendation) {
    if (profile!.loadOrder.some((e) => e.path === r.path)) return;
    patch({ loadOrder: [...profile!.loadOrder, { path: r.path, name: r.name, group: r.group, enabled: true }] });
    setRecs((rs) => rs?.filter((x) => x.path !== r.path) ?? null);
  }

  async function aiDescribe() {
    if (!settings.aiKey) return setToast(t("settings.aiKey"));
    try {
      const text = await api.aiDescribeBuild(settings.aiKey, settings.aiModel, profile!.loadOrder.filter((e) => e.enabled).map((e) => e.name));
      patch({ description: text });
    } catch (e) { setToast(String(e)); }
  }

  async function genReport() { setReport(await api.generateReport(profile!)); }
  async function saveReport() {
    if (!report) return;
    const dest = await save({ defaultPath: `${profile!.name}-report.md`, filters: [{ name: "Markdown", extensions: ["md"] }] });
    if (dest) { await api.saveText(dest, report); setToast("OK"); }
  }

  const enabled = profile.loadOrder.filter((e) => e.enabled).length;

  return (
    <div className="build view-narrow">
      <div className="build-head">
        <input className="title-input" value={profile.name} onChange={(e) => patch({ name: e.target.value })} />
        <div className="btn-row">
          <button className="btn" onClick={persist}><Icon name="save" /> {t("common.save")}</button>
          <button className="btn" onClick={exportBuild}><Icon name="export" /> {t("common.export")}</button>
          <button className="btn danger" onClick={remove}><Icon name="trash" /> {t("common.delete")}</button>
        </div>
      </div>

      <div className="desc-row">
        <textarea placeholder={t("build.description")} value={profile.description} onChange={(e) => patch({ description: e.target.value })} />
        <button className="btn sm" onClick={aiDescribe}><Icon name="spark" size={14} /> {t("build.describe")}</button>
      </div>

      <div className="cfg">
        <div className="field-with-btn">
          <label className="field">
            {t("build.engine")}
            <select value={profile.enginePath ?? ""} onChange={(e) => patch({ enginePath: e.target.value || undefined })}>
              <option value="">{t("build.auto")} ({engines[0]?.name ?? t("common.none")})</option>
              {engines.map((e) => <option key={e.path} value={e.path}>{e.name}{e.version ? ` (${e.version})` : ""}</option>)}
            </select>
          </label>
          <button className="btn sm" title={t("build.pickEngine")} onClick={pickEngineFile}><Icon name="folder" size={15} /></button>
        </div>
        <div className="field-with-btn">
          <label className="field">
            {t("build.iwad")}
            <select value={profile.iwad ?? ""} onChange={(e) => patch({ iwad: e.target.value || undefined })}>
              <option value="">{t("build.selectIwad")}</option>
              {iwads.filter((i) => i.present).map((i) => <option key={i.fileName} value={i.path ?? i.fileName}>{i.title}</option>)}
              {profile.iwad && !iwads.some((i) => (i.path ?? i.fileName) === profile.iwad) && (
                <option value={profile.iwad}>{profile.iwad}</option>
              )}
            </select>
          </label>
          <button className="btn sm" title={t("build.pickIwad")} onClick={pickIwadFile}><Icon name="folder" size={15} /></button>
        </div>
      </div>

      <CompatBar profile={profile} />

      <div className="lo-head">
        <h3>{t("build.loadOrder")} <span className="muted">({enabled}/{profile.loadOrder.length} {t("build.enabled")})</span></h3>
        <div className="btn-row">
          <button className="btn sm" onClick={addFiles}><Icon name="plus" size={14} /> {t("build.addFiles")}</button>
          <button className="btn sm" onClick={autoSort}><Icon name="sort" size={14} /> {t("build.autosort")}</button>
          <button className="btn sm" onClick={recommend}><Icon name="spark" size={14} /> {t("build.recommend")}</button>
          <button className="btn sm" onClick={() => setShowGraph((s) => !s)}><Icon name="graph" size={14} /> {showGraph ? t("build.hideGraph") : t("build.graph")}</button>
        </div>
      </div>

      {recs && (
        <div className="recs">
          {recs.length === 0 && <span className="empty">—</span>}
          {recs.map((r) => (
            <button key={r.path} className="btn sm rec-chip" onClick={() => addRec(r)} title={r.reason}>
              <Icon name="plus" size={13} /> {r.name}
            </button>
          ))}
        </div>
      )}

      {showGraph && <DependencyGraph profile={profile} />}

      <LoadOrderEditor entries={profile.loadOrder} onChange={(loadOrder) => patch({ loadOrder })} />

      <div className="launch">
        <button className="btn primary lg" onClick={() => launch(false)}><Icon name="play" /> {t("build.launch")}</button>
        <button className="btn" onClick={() => launch(true)}><Icon name="shield" /> {t("build.safeMode")}</button>
        <button className="btn" onClick={autotest}><Icon name="check" /> {t("build.autotest")}</button>
        <span className="spacer" />
        <button className="btn sm" onClick={async () => setToast(`${(await api.recordOutcome(profile!.id, false)).rating}%`)}><Icon name="check" size={14} /> {t("build.ranFine")}</button>
        <button className="btn sm" onClick={async () => setToast(`${(await api.recordOutcome(profile!.id, true)).rating}%`)}><Icon name="crash" size={14} /> {t("build.crashed")}</button>
      </div>

      {cmd && <pre className="cmd" onClick={() => setCmd(null)}>{cmd}</pre>}

      <details className="block"><summary>{t("build.history")}</summary><div style={{ marginTop: 10 }}><SnapshotsPanel profile={profile} /></div></details>
      <details className="block">
        <summary>{t("build.report")}</summary>
        <div className="btn-row" style={{ marginTop: 10 }}>
          <button className="btn sm" onClick={genReport}>{t("build.generate")}</button>
          {report && <button className="btn sm" onClick={saveReport}><Icon name="save" size={14} /> .md</button>}
        </div>
        {report && <pre className="report">{report}</pre>}
      </details>
    </div>
  );
}
