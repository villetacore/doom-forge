import { useMemo, useState } from "react";
import { api } from "../../lib/api";
import { useStore } from "../../store/store";
import { useT } from "../../i18n";
import { Icon } from "../../components/Icon";
import { EmptyHero } from "../../components/EmptyHero";
import { GROUP_LABELS, GROUP_ORDER, type DuplicateGroup, type ModFile } from "../../lib/types";

function fmtSize(b: number) {
  if (b > 1 << 20) return `${(b / (1 << 20)).toFixed(1)} MB`;
  if (b > 1 << 10) return `${(b / (1 << 10)).toFixed(0)} KB`;
  return `${b} B`;
}

export default function LibraryView() {
  const t = useT();
  const { mods, setMods, profiles, setProfiles, activeProfileId, setToast } = useStore();
  const [filter, setFilter] = useState("");
  const [dupes, setDupes] = useState<DuplicateGroup[] | null>(null);
  const [q, setQ] = useState("");
  const [hits, setHits] = useState<string[] | null>(null);

  const profile = profiles.find((p) => p.id === activeProfileId) ?? null;

  const filtered = useMemo(() => {
    const f = filter.toLowerCase();
    return mods.filter((m) => !f || m.name.toLowerCase().includes(f) || m.tags.some((t) => t.toLowerCase().includes(f)));
  }, [mods, filter]);

  function addToBuild(mod: ModFile) {
    if (!profile) return setToast(t("build.empty"));
    if (profile.loadOrder.some((e) => e.path === mod.path)) return;
    const next = { ...profile, loadOrder: [...profile.loadOrder, { path: mod.path, name: mod.name, group: mod.group, enabled: true }] };
    setProfiles(profiles.map((p) => (p.id === next.id ? next : p)));
    setToast("OK");
  }
  function addTag(mod: ModFile) {
    const tag = window.prompt(t("library.tag"))?.trim();
    if (!tag) return;
    setMods(mods.map((m) => (m.path === mod.path && !m.tags.includes(tag) ? { ...m, tags: [...m.tags, tag] } : m)));
  }

  if (mods.length === 0)
    return <EmptyHero art="demon" title={t("library.emptyTitle")} hint={t("library.empty")} />;

  return (
    <div>
      <div className="lib-toolbar">
        <input placeholder={t("library.filter")} value={filter} onChange={(e) => setFilter(e.target.value)} />
        <button className="btn" onClick={async () => setDupes(await api.findDuplicates(mods))}>
          <Icon name="search" size={15} /> {t("library.findDupes")}
        </button>
        <div className="src row" style={{ marginBottom: 0 }}>
          <input placeholder={t("library.searchInside")} value={q} onChange={(e) => setQ(e.target.value)}
            onKeyDown={async (e) => { if (e.key === "Enter" && q.trim()) setHits(await api.searchModContents(mods, q.trim())); }} />
        </div>
      </div>

      {dupes && (
        <div className="findings">
          <h4>{t("library.duplicates")} {dupes.length === 0 && `— ${t("library.noDuplicates")}`}</h4>
          {dupes.map((d, i) => (<div key={i}><strong>{d.reason}</strong><ul>{d.files.map((f) => <li key={f}>{f}</li>)}</ul></div>))}
          <button className="btn sm ghost" onClick={() => setDupes(null)}>{t("common.dismiss")}</button>
        </div>
      )}
      {hits && (
        <div className="findings">
          <h4>“{q}” — {hits.length}</h4>
          <ul>{hits.map((f) => <li key={f}>{f}</li>)}</ul>
          <button className="btn sm ghost" onClick={() => setHits(null)}>{t("common.dismiss")}</button>
        </div>
      )}

      {GROUP_ORDER.map((group) => {
        const items = filtered.filter((m) => m.group === group);
        if (items.length === 0) return null;
        return (
          <section key={group} className="mod-group">
            <h4>{GROUP_LABELS[group]} <span>({items.length})</span></h4>
            <div className="mod-grid">
              {items.map((m) => (
                <div className="mod-card" key={m.path}>
                  <div className="name" title={m.path}>{m.name}</div>
                  <div className="meta"><span className="tag">{m.extension}</span><span>{fmtSize(m.size)}</span></div>
                  {m.tags.length > 0 && <div className="pkg-tags">{m.tags.map((t) => <span key={t} className="tag">{t}</span>)}</div>}
                  <div className="card-actions">
                    <button className="btn sm" onClick={() => addToBuild(m)}><Icon name="plus" size={13} /> {t("library.addToBuild")}</button>
                    <button className="btn sm ghost" onClick={() => addTag(m)}><Icon name="tag" size={13} /></button>
                  </div>
                </div>
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
}
