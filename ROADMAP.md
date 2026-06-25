# DoomForge roadmap

The MVP core (see README) is the foundation. Below is how the rest of the
requested features map onto the existing architecture.

## Advanced

- [ ] **Known-conflicts database** — JSON/SQLite table keyed by mod name/hash;
      checked when building a profile. New module `conflicts.rs`.
- [ ] **Incompatibility warnings** + **compatibility score (%)** — derived from
      the conflicts DB over the active load order.
- [ ] **Dependency graph** — visual graph in the frontend (e.g. reactflow).
- [ ] **Auto compatibility patches** — patch suggestions from the conflicts DB.
- [ ] **Compare two builds** — diff of load orders + settings.
- [ ] **Profile history / snapshots / rollback** — version each `save_profile`
      into `profiles/<id>/history/`.
- [ ] **Tags & groups** — tags already exist on `ModFile`; surface tag editing.

## Unique

- [ ] **Crash log analysis** + **culprit mod detection** — parse GZDoom logs,
      correlate with load order. New module `logs.rs`.
- [ ] **Stability rating** — local per-build success/crash counter.
- [ ] **Problem report generation** — bundle profile + logs + system info.

## "Heavy" / online

- [ ] **Doomworld / ModDB browsers**, **one-click install**, **screenshots**,
      **changelogs**, **auto-update** — needs an HTTP client (`reqwest`) and
      source adapters.
- [ ] **Cloud sync**, **share via link**, **public build catalog**,
      **import by URL**.

## "Almost nobody has this"

- [ ] **Package manager** (`doom add brutal-doom && doom run`) — a CLI binary
      sharing the core crate + a registry.
- [ ] **AI** log analysis / conflict detection / load-order generation /
      similar-mod search / build description / auto-categorization — calls the
      Claude API (`claude-opus-4-8`) behind a `ai.rs` module.
- [ ] **"One button — build me a meaty 2026 set"** — AI-assembled profile.
