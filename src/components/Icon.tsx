// Minimal line-icon set (no emoji — renders identically on every OS).
// Each icon is a 24x24 stroked path/group.

export type IconName =
  | "build"
  | "library"
  | "browse"
  | "compare"
  | "crash"
  | "status"
  | "settings"
  | "play"
  | "plus"
  | "trash"
  | "save"
  | "export"
  | "search"
  | "sort"
  | "graph"
  | "shield"
  | "refresh"
  | "folder"
  | "tag"
  | "download"
  | "check"
  | "spark"
  | "flame"
  | "skull"
  | "link"
  | "info"
  | "close"
  | "bolt";

const PATHS: Record<IconName, JSX.Element> = {
  build: <path d="M4 20l5-5M14 6l4 4M12 8l4-4 4 4-4 4M3 21l6-6" />,
  library: <path d="M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z" />,
  browse: <path d="M12 3v12m0 0l-4-4m4 4l4-4M5 21h14" />,
  compare: <path d="M9 4v16M15 4v16M4 8l5-4M20 16l-5 4" />,
  crash: <path d="M3 12h4l2 6 4-14 2 8h6" />,
  status: <path d="M4 5h16v6H4zM4 13h16v6H4zM8 8h.01M8 16h.01" />,
  settings: (
    <path d="M12 9a3 3 0 100 6 3 3 0 000-6zM19 12a7 7 0 00-.1-1l2-1.5-2-3.5-2.4 1a7 7 0 00-1.7-1L14.5 2h-5l-.3 2.5a7 7 0 00-1.7 1l-2.4-1-2 3.5 2 1.5a7 7 0 000 2l-2 1.5 2 3.5 2.4-1a7 7 0 001.7 1l.3 2.5h5l.3-2.5a7 7 0 001.7-1l2.4 1 2-3.5-2-1.5a7 7 0 00.1-1z" />
  ),
  play: <path d="M7 4l13 8-13 8z" />,
  plus: <path d="M12 5v14M5 12h14" />,
  trash: <path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13" />,
  save: <path d="M5 3h12l4 4v14H5zM8 3v6h8V3M8 21v-6h8v6" />,
  export: <path d="M12 16V4m0 0l-4 4m4-4l4 4M4 20h16" />,
  search: <path d="M11 4a7 7 0 100 14 7 7 0 000-14zM21 21l-4.5-4.5" />,
  sort: <path d="M7 4v16M7 20l-3-3M7 4l3 3M14 7h7M14 12h5M14 17h3" />,
  graph: <path d="M5 7a2 2 0 100-4 2 2 0 000 4zM5 21a2 2 0 100-4 2 2 0 000 4zM19 14a2 2 0 100-4 2 2 0 000 4zM5 5v14M7 19l10-7M7 5l10 7" />,
  shield: <path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z" />,
  refresh: <path d="M20 11a8 8 0 10-2 5m2 4v-5h-5" />,
  folder: <path d="M3 6h6l2 2h10v11H3z" />,
  tag: <path d="M3 12l9-9 9 9-9 9zM12 7h.01" />,
  download: <path d="M12 4v10m0 0l-4-4m4 4l4-4M5 20h14" />,
  check: <path d="M5 13l4 4L19 7" />,
  spark: <path d="M12 3l2.2 6.3L21 12l-6.8 2.7L12 21l-2.2-6.3L3 12l6.8-2.7z" />,
  flame: <path d="M12 3c1 4 5 5 5 9a5 5 0 11-10 0c0-2 1-3 2-4 .5 2 2 2 3 1-1-2 0-5 0-6z" />,
  skull: <path d="M5 4C3 5 2 9 4 13l1 3 2-1 2 1 2-1 2 1 2-1 1 3 2-1c2-4 1-8-1-9M9 9h.01M15 9h.01M11 14h2" />,
  link: <path d="M10 14a4 4 0 005.7 0l3-3a4 4 0 00-5.7-5.7l-1.5 1.5M14 10a4 4 0 00-5.7 0l-3 3a4 4 0 005.7 5.7l1.5-1.5" />,
  info: <path d="M12 21a9 9 0 100-18 9 9 0 000 18zM12 11v5M12 8h.01" />,
  close: <path d="M6 6l12 12M18 6L6 18" />,
  bolt: <path d="M13 3L5 13h6l-1 8 8-10h-6z" />,
};

export function Icon({
  name,
  size = 18,
  className,
}: {
  name: IconName;
  size?: number;
  className?: string;
}) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.7}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {PATHS[name]}
    </svg>
  );
}
