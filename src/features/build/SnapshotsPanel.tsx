import { useEffect, useState } from "react";
import { api } from "../../lib/api";
import { useStore } from "../../store/store";
import { useT } from "../../i18n";
import { Icon } from "../../components/Icon";
import type { Profile, SnapshotMeta } from "../../lib/types";

export default function SnapshotsPanel({ profile }: { profile: Profile }) {
  const t = useT();
  const { profiles, setProfiles, setToast } = useStore();
  const [snaps, setSnaps] = useState<SnapshotMeta[]>([]);
  const [label, setLabel] = useState("");

  function refresh() {
    api.listSnapshots(profile.id).then(setSnaps).catch(() => setSnaps([]));
  }
  useEffect(refresh, [profile.id]);

  async function create() {
    await api.createSnapshot(profile, label);
    setLabel("");
    refresh();
    setToast("OK");
  }
  async function restore(id: string) {
    const restored = await api.restoreSnapshot(profile.id, id);
    setProfiles(profiles.map((p) => (p.id === restored.id ? restored : p)));
    setToast("OK");
  }
  async function remove(id: string) {
    await api.deleteSnapshot(profile.id, id);
    refresh();
  }

  return (
    <div>
      <div className="snap-new">
        <input placeholder="…" value={label} onChange={(e) => setLabel(e.target.value)} />
        <button className="btn sm" onClick={create}><Icon name="save" size={14} /> {t("common.save")}</button>
      </div>
      {snaps.length === 0 && <p className="empty">—</p>}
      {snaps.map((s) => (
        <div className="snap-row" key={s.id}>
          <span className="lbl">{s.label}</span>
          <span className="muted" style={{ fontSize: 11 }}>
            {new Date(s.createdAt).toLocaleString()} · {s.entryCount}
          </span>
          <button className="btn sm" onClick={() => restore(s.id)}><Icon name="refresh" size={13} /></button>
          <button className="icon-btn" onClick={() => remove(s.id)}><Icon name="trash" size={14} /></button>
        </div>
      ))}
    </div>
  );
}
