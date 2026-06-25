import { en } from "./en";
import { ru } from "./ru";
import { uk } from "./uk";
import { de } from "./de";
import { fr } from "./fr";
import { es } from "./es";
import { it } from "./it";
import { pt } from "./pt";
import { pl } from "./pl";
import { zh } from "./zh";
import { ja } from "./ja";
import { useStore } from "../store/store";

export type Lang =
  | "en"
  | "ru"
  | "uk"
  | "de"
  | "fr"
  | "es"
  | "it"
  | "pt"
  | "pl"
  | "zh"
  | "ja";

export const LANGUAGES: { id: Lang; label: string }[] = [
  { id: "en", label: "English" },
  { id: "ru", label: "Русский" },
  { id: "uk", label: "Українська" },
  { id: "de", label: "Deutsch" },
  { id: "fr", label: "Français" },
  { id: "es", label: "Español" },
  { id: "it", label: "Italiano" },
  { id: "pt", label: "Português" },
  { id: "pl", label: "Polski" },
  { id: "zh", label: "中文" },
  { id: "ja", label: "日本語" },
];

export const DICTS: Record<Lang, Record<string, string>> = {
  en, ru, uk, de, fr, es, it, pt, pl, zh, ja,
};

export function translate(lang: Lang, key: string): string {
  return DICTS[lang]?.[key] ?? en[key] ?? key;
}

/** Hook returning a `t(key)` bound to the current language setting. */
export function useT() {
  const lang = useStore((s) => s.settings.lang);
  return (key: string) => translate(lang, key);
}
