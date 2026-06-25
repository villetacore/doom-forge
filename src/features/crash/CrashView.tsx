import { useMemo, useState } from "react";
import { open } from "@tauri-apps/plugin-dialog";
import { api } from "../../lib/api";
import { useStore } from "../../store/store";
import { useT } from "../../i18n";
import { Icon } from "../../components/Icon";
import type { LogAnalysis } from "../../lib/types";

export default function CrashView() {
  const t = useT();
  const { profiles, activeProfileId, settings, setToast } = useStore();
  const [text, setText] = useState("");
  const [result, setResult] = useState<LogAnalysis | null>(null);
  const [ai, setAi] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const profile = useMemo(() => profiles.find((p) => p.id === activeProfileId) ?? null, [profiles, activeProfileId]);

  async function openFile() {
    const f = await open({ multiple: false, filters: [{ name: "Log", extensions: ["txt", "log"] }] });
    if (typeof f === "string" && profile) setResult(await api.analyzeLogFile(f, profile));
  }
  async function analyze() {
    if (!profile) return setToast(t("build.empty"));
    setResult(await api.analyzeLogText(text, profile));
  }
  async function aiAnalyze() {
    if (!profile) return;
    if (!settings.aiKey) return setToast(t("settings.aiKey"));
    setBusy(true);
    try {
      setAi(await api.aiAnalyzeLog(settings.aiKey, settings.aiModel, text, profile.loadOrder.filter((e) => e.enabled).map((e) => e.name)));
    } catch (e) { setToast(String(e)); } finally { setBusy(false); }
  }

  return (
    <div className="view-narrow">
      <p className="sec-hint">{t("crash.hint")}</p>
      <div className="btn-row">
        <button className="btn" onClick={openFile}><Icon name="folder" size={15} /> {t("crash.openFile")}</button>
        <button className="btn" onClick={analyze} disabled={!text.trim()}><Icon name="search" size={15} /> {t("crash.analyze")}</button>
        <button className="btn" onClick={aiAnalyze} disabled={!text.trim() || busy}><Icon name="spark" size={15} /> {t("crash.ai")}</button>
      </div>
      <textarea className="crash-input" placeholder={t("crash.paste")} value={text} onChange={(e) => setText(e.target.value)} />

      {result && (
        <div className="crash-out">
          <h4>{result.summary}</h4>
          {result.suspectMods.length > 0 && (<><strong>{t("crash.suspects")}:</strong><ol>{result.suspectMods.map((m) => <li key={m}>{m}</li>)}</ol></>)}
          {result.signals.length > 0 && (<><strong>{t("crash.signals")}:</strong><ul>{result.signals.map((s) => <li key={s}>{s}</li>)}</ul></>)}
        </div>
      )}
      {ai && (<div className="crash-out ai"><h4>{t("crash.ai")}</h4><p style={{ whiteSpace: "pre-wrap" }}>{ai}</p></div>)}
    </div>
  );
}
