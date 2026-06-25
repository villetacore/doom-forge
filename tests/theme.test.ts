import { describe, it, expect } from "vitest";
import { applyTheme, PALETTES, THEME_MODES } from "../src/theme/themes";

describe("themes", () => {
  it("exposes multiple base modes and accent palettes", () => {
    expect(THEME_MODES.length).toBeGreaterThanOrEqual(3);
    expect(PALETTES.length).toBeGreaterThanOrEqual(8);
  });

  it("has unique palette ids and valid hex accents", () => {
    const ids = PALETTES.map((p) => p.id);
    expect(new Set(ids).size).toBe(ids.length);
    for (const p of PALETTES) {
      expect(p.accent, `bad accent for ${p.id}`).toMatch(/^#[0-9a-fA-F]{6}$/);
      expect(p.accent2, `bad accent2 for ${p.id}`).toMatch(/^#[0-9a-fA-F]{6}$/);
    }
  });

  it("writes the expected CSS custom properties onto <html>", () => {
    applyTheme("dark", "toxic");
    const root = document.documentElement;
    expect(root.style.getPropertyValue("--accent")).toBe("#4caf50");
    expect(root.getAttribute("data-theme")).toBe("dark");
    expect(root.getAttribute("data-palette")).toBe("toxic");
    expect(root.style.getPropertyValue("--bg")).not.toBe("");

    applyTheme("light", "ember");
    expect(root.getAttribute("data-theme")).toBe("light");
    expect(root.style.getPropertyValue("--accent")).toBe("#e2603a");
  });

  it("maps the amoled mode to a dark data-theme with a pure-black bg", () => {
    applyTheme("amoled", "ember");
    const root = document.documentElement;
    expect(root.getAttribute("data-mode")).toBe("amoled");
    expect(root.getAttribute("data-theme")).toBe("dark");
    expect(root.style.getPropertyValue("--bg")).toBe("#000000");
  });
});
