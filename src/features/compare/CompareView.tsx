import { useState } from "react";
import { api } from "../../lib/api";
import { useStore } from "../../store/store";
import { useT } from "../../i18n";
import type { ProfileDiff } from "../../lib/types";

export default function CompareView() {
  const t = useT();
  const { profiles } = useStore();
  const [aId, setAId] = useState("");
  const [bId, setBId] = useState("");
  const [diff, setDiff] = useState<ProfileDiff | null>(null);

  async function compare() {
    const a = profiles.find((p) => p.id === aId);
    const b = profiles.find((p) => p.id === bId);
    if (a && b) setDiff(await api.compareProfiles(a, b));
  }

  return (
    <div className="view-narrow">
      <div className="cmp-pick">
        <select value={aId} onChange={(e) => setAId(e.target.value)}>
          <option value="">A — {t("compare.pick")}</option>
          {profiles.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <span className="muted">vs</span>
        <select value={bId} onChange={(e) => setBId(e.target.value)}>
          <option value="">B — {t("compare.pick")}</option>
          {profiles.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <button className="btn primary" disabled={!aId || !bId} onClick={compare}>{t("nav.compare")}</button>
      </div>

      {diff && (
        <div className="diff">
          <div>
            <h4 className="a">{t("compare.onlyA")} ({diff.onlyInA.length})</h4>
            <ul>{diff.onlyInA.map((n) => <li key={n}>{n}</li>)}</ul>
          </div>
          <div>
            <h4>{t("compare.common")} ({diff.common.length}) {diff.reordered && <em className="muted">· {t("compare.reordered")}</em>}</h4>
            <ul className="muted">{diff.common.map((n) => <li key={n}>{n}</li>)}</ul>
          </div>
          <div>
            <h4 className="b">{t("compare.onlyB")} ({diff.onlyInB.length})</h4>
            <ul>{diff.onlyInB.map((n) => <li key={n}>{n}</li>)}</ul>
          </div>
        </div>
      )}
    </div>
  );
}
