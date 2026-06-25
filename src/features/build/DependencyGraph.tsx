import { useEffect, useState } from "react";
import { api } from "../../lib/api";
import { useT } from "../../i18n";
import type { ModGraph, Profile } from "../../lib/types";

const GROUP_COLOR: Record<string, string> = {
  maps: "#6fb1ff",
  gameplay: "var(--accent-2)",
  audio: "#c08fff",
  visuals: "#5fd0c0",
  patch: "var(--err)",
  other: "var(--muted)",
};

export default function DependencyGraph({ profile }: { profile: Profile }) {
  const t = useT();
  const [graph, setGraph] = useState<ModGraph | null>(null);

  useEffect(() => {
    api.modGraph(profile).then(setGraph).catch(() => setGraph(null));
  }, [profile.loadOrder]);

  if (!graph || graph.nodes.length === 0) {
    return <p className="empty">{t("build.loadOrderEmpty")}</p>;
  }

  const rowH = 44;
  const w = 540;
  const h = graph.nodes.length * rowH + 24;
  const x = 150;
  const pos = new Map(graph.nodes.map((n, i) => [n.id, { x, y: 26 + i * rowH }]));

  return (
    <svg className="dep-graph" width={w} height={h}>
      {graph.edges.map((e, i) => {
        const a = pos.get(e.from);
        const b = pos.get(e.to);
        if (!a || !b) return null;
        if (e.kind === "conflict") {
          const midY = (a.y + b.y) / 2;
          const bend = x + 120 + Math.abs(a.y - b.y) * 0.3;
          return (
            <path
              key={i}
              d={`M ${a.x} ${a.y} Q ${bend} ${midY} ${b.x} ${b.y}`}
              fill="none"
              stroke="var(--err)"
              strokeWidth={2}
              strokeDasharray="5 4"
            />
          );
        }
        return <line key={i} x1={a.x} y1={a.y} x2={b.x} y2={b.y} stroke="var(--line)" strokeWidth={2} />;
      })}
      {graph.nodes.map((n) => {
        const p = pos.get(n.id)!;
        return (
          <g key={n.id}>
            <circle cx={p.x} cy={p.y} r={7} fill={GROUP_COLOR[n.group]} />
            <text x={p.x + 15} y={p.y + 4} fill="var(--fg)" fontSize={12}>{n.name}</text>
          </g>
        );
      })}
    </svg>
  );
}
