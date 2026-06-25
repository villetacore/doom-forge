import { useEffect, useState } from "react";
import { api } from "../../lib/api";
import { useT } from "../../i18n";
import type { CompatReport, Profile, Stability } from "../../lib/types";

/** Compatibility score + conflicts/warnings for a build. */
export default function CompatBar({ profile }: { profile: Profile }) {
  const t = useT();
  const [report, setReport] = useState<CompatReport | null>(null);
  const [stab, setStab] = useState<Stability | null>(null);

  useEffect(() => {
    api.evaluateCompat(profile).then(setReport).catch(() => setReport(null));
    api.getStability(profile.id).then(setStab).catch(() => setStab(null));
  }, [profile.loadOrder, profile.iwad]);

  if (!report) return null;
  const color = report.score >= 80 ? "var(--ok)" : report.score >= 50 ? "var(--accent-2)" : "var(--err)";

  return (
    <div className="panel">
      <div className="compat-head">
        <span>{t("compat.title")}</span>
        <strong style={{ color }}>{report.score}%</strong>
        {stab && stab.launches > 0 && (
          <span className="muted" title={`${stab.launches} / ${stab.crashes}`}>
            · {t("compat.stability")} {stab.rating}%
          </span>
        )}
      </div>
      <div className="track">
        <div style={{ width: `${report.score}%`, background: color }} />
      </div>
      {report.hits.map((h, i) => (
        <div key={i} className={`conflict sev-${h.severity}`}>
          <span className="sev">{h.severity}</span>
          <span>
            <strong>{h.a}</strong> ↔ <strong>{h.b}</strong> — {h.note}
            {h.patch && <em> {h.patch}</em>}
          </span>
        </div>
      ))}
      {report.warnings.map((w, i) => (
        <div key={i} className="conflict sev-warn">
          <span className="sev">warn</span>
          <span>{w}</span>
        </div>
      ))}
    </div>
  );
}
