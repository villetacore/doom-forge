// Original Doom-inspired vector artwork. Hand-drawn SVG (no bundled copyrighted
// id Software assets) so it stays crisp at any size and themes with the palette
// via the --accent / --accent-2 / --bg CSS variables. Used for the brand mark,
// empty states and the favicon (kept in sync with /public/favicon.svg).

/** The DoomForge brand mark: a horned demon skull set in a forged hex badge. */
export function BrandMark({ size = 26 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      fill="none"
      aria-hidden="true"
      className="brand-mark"
    >
      <defs>
        <linearGradient id="bm-badge" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="var(--accent-2)" />
          <stop offset="1" stopColor="var(--accent)" />
        </linearGradient>
        <radialGradient id="bm-eye" cx="0.5" cy="0.5" r="0.5">
          <stop offset="0" stopColor="#fff7e8" />
          <stop offset="0.5" stopColor="var(--accent-2)" />
          <stop offset="1" stopColor="var(--accent)" />
        </radialGradient>
      </defs>
      {/* forged hex badge */}
      <path
        d="M32 2 56 16 56 48 32 62 8 48 8 16Z"
        fill="url(#bm-badge)"
        opacity="0.16"
      />
      <path
        d="M32 2 56 16 56 48 32 62 8 48 8 16Z"
        fill="none"
        stroke="url(#bm-badge)"
        strokeWidth="2.4"
        strokeLinejoin="round"
      />
      {/* horns */}
      <path
        d="M21 22c-5-2-9-6-10-12 5 1 9 3 12 7M43 22c5-2 9-6 10-12-5 1-9 3-12 7"
        fill="none"
        stroke="var(--accent-2)"
        strokeWidth="2.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      {/* cranium + cheeks */}
      <path
        d="M32 14c-9 0-15 6-15 15 0 5 2 8 5 11l1 7 4-2 5 2 5-2 4 2 1-7c3-3 5-6 5-11 0-9-6-15-15-15Z"
        fill="var(--bg)"
        stroke="url(#bm-badge)"
        strokeWidth="2.2"
        strokeLinejoin="round"
      />
      {/* eyes */}
      <path d="M22 30l8 3-2 5-7-3z" fill="url(#bm-eye)" />
      <path d="M42 30l-8 3 2 5 7-3z" fill="url(#bm-eye)" />
      {/* snout + fangs */}
      <path
        d="M30 40h4l-2 5zM27 44l2 5M37 44l-2 5M32 45l0 5"
        stroke="var(--accent-2)"
        strokeWidth="1.8"
        strokeLinecap="round"
        fill="none"
      />
    </svg>
  );
}

export type HeroName = "helmet" | "demon" | "skull" | "rune";

/** Large decorative art for empty states, themed with the accent palette. */
export function HeroArt({ name, size = 132 }: { name: HeroName; size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 120 120"
      fill="none"
      aria-hidden="true"
      className="hero-art"
    >
      <defs>
        <radialGradient id="ha-glow" cx="0.5" cy="0.45" r="0.6">
          <stop offset="0" stopColor="var(--accent)" stopOpacity="0.35" />
          <stop offset="1" stopColor="var(--accent)" stopOpacity="0" />
        </radialGradient>
        <linearGradient id="ha-stroke" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="var(--accent-2)" />
          <stop offset="1" stopColor="var(--accent)" />
        </linearGradient>
      </defs>
      <circle cx="60" cy="56" r="52" fill="url(#ha-glow)" />
      {name === "helmet" && <Helmet />}
      {name === "demon" && <Cacodemon />}
      {name === "skull" && <DemonSkull />}
      {name === "rune" && <Rune />}
    </svg>
  );
}

const SK = {
  fill: "none",
  stroke: "url(#ha-stroke)",
  strokeWidth: 2.6,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
};

/** A space-marine combat helmet — the launcher's "ready to play" mascot. */
function Helmet() {
  return (
    <g {...SK}>
      <path d="M30 54c0-19 13-31 30-31s30 12 30 31c0 9-3 16-8 22l-3 13-9-4a34 34 0 0 1-20 0l-9 4-3-13c-5-6-8-13-8-22Z" />
      {/* visor */}
      <path d="M40 50c6-5 13-7 20-7s14 2 20 7l-3 16c-5 4-11 6-17 6s-12-2-17-6Z" fill="var(--accent-soft)" />
      <path d="M40 50c6-5 13-7 20-7s14 2 20 7" />
      {/* visor highlight */}
      <path d="M47 52c4-2 8-3 13-3" strokeWidth={1.8} opacity={0.8} />
      {/* crest + vents */}
      <path d="M60 23v9M49 30l3 7M71 30l-3 7" strokeWidth={2} />
    </g>
  );
}

/** A round, one-eyed grinning demon — the classic floating menace, reimagined. */
function Cacodemon() {
  return (
    <g {...SK}>
      <circle cx="60" cy="58" r="36" fill="var(--accent-soft)" />
      {/* horns */}
      <path d="M40 30c-3-6-3-12 0-17 4 4 6 9 6 15M80 30c3-6 3-12 0-17-4 4-6 9-6 15" strokeWidth={2.2} />
      {/* spikes */}
      <path d="M24 58l-9-3 8-4M96 58l9-3-8-4M60 94l0 10" strokeWidth={2} />
      {/* eye */}
      <circle cx="60" cy="50" r="11" fill="var(--bg)" />
      <circle cx="60" cy="50" r="4.5" fill="url(#ha-stroke)" stroke="none" />
      {/* fanged grin */}
      <path d="M40 70c8 9 32 9 40 0" />
      <path d="M46 72l3 7 4-6 4 7 4-7 4 6 3-7" strokeWidth={2} />
    </g>
  );
}

/** A horned demon skull. */
function DemonSkull() {
  return (
    <g {...SK}>
      <path d="M30 24c-7-3-12-9-13-18 7 1 13 5 17 11M90 24c7-3 12-9 13-18-7 1-13 5-17 11" strokeWidth={2.3} />
      <path d="M60 22c-16 0-26 11-26 27 0 9 3 14 9 19l1 12 7-4 9 3 9-3 7 4 1-12c6-5 9-10 9-19 0-16-10-27-26-27Z" fill="var(--bg)" />
      <path d="M44 52l14 5-3 9-12-5z" fill="var(--accent-soft)" stroke="none" />
      <path d="M76 52l-14 5 3 9 12-5z" fill="var(--accent-soft)" stroke="none" />
      <path d="M44 52l14 5-3 9-12-5zM76 52l-14 5 3 9 12-5z" strokeWidth={2.2} />
      <path d="M55 70h10l-5 11zM50 76l3 9M70 76l-3 9M60 81v9" strokeWidth={2.1} />
    </g>
  );
}

/** A glowing hell rune / sigil. */
function Rune() {
  return (
    <g {...SK}>
      <circle cx="60" cy="58" r="34" fill="var(--accent-soft)" />
      <path d="M60 24l30 18-12 36H42L30 42z" />
      <path d="M60 38v40M44 52h32M48 68h24" strokeWidth={2.2} />
      <circle cx="60" cy="58" r="6" fill="url(#ha-stroke)" stroke="none" />
    </g>
  );
}
