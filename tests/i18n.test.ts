import { describe, it, expect } from "vitest";
import { DICTS, LANGUAGES, translate, type Lang } from "../src/i18n";
import { en } from "../src/i18n/en";

const enKeys = Object.keys(en).sort();

describe("i18n", () => {
  it("registers a dictionary for every advertised language", () => {
    for (const { id } of LANGUAGES) {
      expect(DICTS[id], `missing dictionary for ${id}`).toBeTruthy();
    }
  });

  it("every language defines exactly the same keys as English", () => {
    for (const lang of Object.keys(DICTS) as Lang[]) {
      const keys = Object.keys(DICTS[lang]).sort();
      expect(keys, `key mismatch in '${lang}'`).toEqual(enKeys);
    }
  });

  it("no language leaves a value blank", () => {
    for (const lang of Object.keys(DICTS) as Lang[]) {
      for (const [key, value] of Object.entries(DICTS[lang])) {
        expect(value.trim().length, `empty '${key}' in '${lang}'`).toBeGreaterThan(0);
      }
    }
  });

  it("falls back to English, then the key itself, for unknown entries", () => {
    expect(translate("de", "nav.build")).toBe(DICTS.de["nav.build"]);
    expect(translate("ru", "totally.unknown.key")).toBe("totally.unknown.key");
  });
});
