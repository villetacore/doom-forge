import { useEffect, useState } from "react";
import { api } from "../../lib/api";
import { useStore } from "../../store/store";
import { useT } from "../../i18n";
import { Icon } from "../../components/Icon";
import type { PackageEntry } from "../../lib/types";

export default function BrowseView() {
  const t = useT();
  const { settings, setMods, setToast } = useStore();
  const [busy, setBusy] = useState(false);
  const [cat, setCat] = useState<PackageEntry[]>([]);
  const [url, setUrl] = useState("");
  const [idQ, setIdQ] = useState("");
  const [idRes, setIdRes] = useState<PackageEntry[] | null>(null);

  useEffect(() => { api.catalog().then(setCat).catch(() => {}); }, []);

  async function rescan() { if (settings.modsDir) setMods(await api.scanMods(settings.modsDir, true)); }

  async function installCat(p: PackageEntry) {
    if (!settings.modsDir) return setToast(t("library.empty"));
    setBusy(true);
    try { setToast(await api.installCatalog(p.url, settings.modsDir)); await rescan(); }
    catch (e) { setToast(String(e)); } finally { setBusy(false); }
  }
  async function importUrl() {
    if (!settings.modsDir) return setToast(t("library.empty"));
    if (!url.trim()) return;
    setBusy(true);
    try { setToast(await api.importByUrl(url.trim(), settings.modsDir)); await rescan(); setUrl(""); }
    catch (e) { setToast(String(e)); } finally { setBusy(false); }
  }
  async function idSearch() {
    if (!idQ.trim()) return;
    setBusy(true);
    try { setIdRes(await api.idgamesSearch(idQ.trim())); }
    catch (e) { setToast(String(e)); } finally { setBusy(false); }
  }
  async function idInstall(p: PackageEntry) {
    if (!settings.modsDir) return setToast(t("library.empty"));
    setBusy(true);
    try { setToast(await api.importByUrl(p.url, settings.modsDir)); await rescan(); }
    catch (e) { setToast(String(e)); } finally { setBusy(false); }
  }

  return (
    <div className="view-narrow">
      <section className="src">
        <h3 className="sec-title">{t("browse.catalog")}</h3>
        <p className="sec-hint">{t("browse.catalogHint")}</p>
        <div className="pkg-grid">
          {cat.map((p) => (
            <div className="pkg-card" key={p.id}>
              <div className="name">{p.name}</div>
              <div className="desc">{p.description}</div>
              <div className="pkg-tags">{p.tags.map((tg) => <span key={tg} className="tag">{tg}</span>)}</div>
              <button className="btn sm primary" disabled={busy} onClick={() => installCat(p)}>
                <Icon name="download" size={14} /> {t("common.install")}
              </button>
            </div>
          ))}
        </div>
      </section>

      <section className="src panel">
        <h3 className="sec-title">{t("browse.importUrl")}</h3>
        <p className="sec-hint">{t("browse.importHint")}</p>
        <div className="row">
          <input placeholder="https://…/mod.pk3" value={url} onChange={(e) => setUrl(e.target.value)} onKeyDown={(e) => e.key === "Enter" && importUrl()} />
          <button className="btn primary" disabled={busy} onClick={importUrl}><Icon name="download" size={15} /> {t("common.download")}</button>
        </div>
      </section>

      <section className="src">
        <h3 className="sec-title">{t("browse.idgames")}</h3>
        <p className="sec-hint">{t("browse.idgamesHint")}</p>
        <div className="row">
          <input placeholder={t("common.search")} value={idQ} onChange={(e) => setIdQ(e.target.value)} onKeyDown={(e) => e.key === "Enter" && idSearch()} />
          <button className="btn" disabled={busy} onClick={idSearch}><Icon name="search" size={15} /> {t("common.search")}</button>
        </div>
        {idRes && idRes.length === 0 && <p className="empty">—</p>}
        <div className="pkg-grid">
          {idRes?.map((p) => (
            <div className="pkg-card" key={p.id}>
              <div className="name">{p.name}</div>
              <div className="desc">{p.description}</div>
              <button className="btn sm" disabled={busy} onClick={() => idInstall(p)}><Icon name="download" size={14} /> {t("common.download")}</button>
            </div>
          ))}
        </div>
      </section>

      <section className="src panel">
        <h3 className="sec-title">{t("browse.moddb")}</h3>
        <p className="sec-hint">{t("browse.moddbHint")}</p>
      </section>
    </div>
  );
}
