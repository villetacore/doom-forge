import { useState } from "react";
import { api } from "../../lib/api";
import { useStore } from "../../store/store";
import { useT } from "../../i18n";
import { Icon } from "../../components/Icon";

export default function StatusView() {
  const t = useT();
  const { engines, setEngines, iwads, setIwads, settings, setToast } = useStore();
  const [busy, setBusy] = useState<string | null>(null);
  const present = iwads.filter((i) => i.present).length;

  async function detect() {
    setBusy("detect");
    try {
      const found = await api.detectEngines();
      const merged = [...engines];
      for (const e of found) if (!merged.some((m) => m.path === e.path)) merged.push(e);
      setEngines(merged);
      setToast(`${found.length}`);
    } catch (e) { setToast(String(e)); } finally { setBusy(null); }
  }
  async function getGz() {
    if (!settings.engineDir) return setToast(t("sidebar.engines"));
    setBusy("gz");
    try { setToast(await api.installGzdoom(settings.engineDir)); setEngines(await api.scanEngines(settings.engineDir)); }
    catch (e) { setToast(String(e)); } finally { setBusy(null); }
  }
  async function getFd() {
    const dir = settings.iwadDirs[0];
    if (!dir) return setToast(t("sidebar.iwads"));
    setBusy("fd");
    try { const w = await api.installFreedoom(dir); setIwads(await api.checkIwads(settings.iwadDirs.filter(Boolean))); setToast(`${w.length}`); }
    catch (e) { setToast(String(e)); } finally { setBusy(null); }
  }

  return (
    <div className="view-narrow">
      <section style={{ marginBottom: 26 }}>
        <div className="status-head">
          <h3>{t("status.engines")}</h3>
          <span className="muted">{engines.length} {t("status.detected")}</span>
          <span className="spacer" />
          <button className="btn sm" disabled={!!busy} onClick={detect}><Icon name="search" size={14} /> {t("status.detect")}</button>
          <button className="btn sm" disabled={!!busy} onClick={getGz}><Icon name="download" size={14} /> {t("status.getGzdoom")}</button>
        </div>
        {engines.length === 0 && <p className="empty">{t("status.noEngines")}</p>}
        <table className="tbl"><tbody>
          {engines.map((e) => (
            <tr key={e.path}><td>{e.name}</td><td className="ver">{e.version ?? "?"}</td><td className="path" title={e.path}>{e.path}</td></tr>
          ))}
        </tbody></table>
      </section>

      <section>
        <div className="status-head">
          <h3>{t("status.iwads")}</h3>
          <span className="muted">{present}/{iwads.length} {t("status.found")}</span>
          <span className="spacer" />
          <button className="btn sm" disabled={!!busy} onClick={getFd}><Icon name="download" size={14} /> {t("status.getFreedoom")}</button>
        </div>
        <table className="tbl"><tbody>
          {iwads.map((i) => (
            <tr key={i.fileName} className={i.present ? "" : "missing"}>
              <td>{i.present ? <Icon name="check" size={15} /> : "—"}</td>
              <td>{i.title}</td><td className="ver">{i.fileName}</td><td className="path" title={i.path ?? ""}>{i.path ?? "—"}</td>
            </tr>
          ))}
        </tbody></table>
      </section>
    </div>
  );
}
