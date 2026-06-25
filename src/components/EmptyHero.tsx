import type { ReactNode } from "react";
import { HeroArt, type HeroName } from "./art";

/** A centered, illustrated empty state with optional call-to-action children. */
export function EmptyHero({
  art,
  title,
  hint,
  children,
}: {
  art: HeroName;
  title: string;
  hint: string;
  children?: ReactNode;
}) {
  return (
    <div className="empty-hero">
      <HeroArt name={art} />
      <h2>{title}</h2>
      <p>{hint}</p>
      {children}
    </div>
  );
}
