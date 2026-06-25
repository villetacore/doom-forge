import { useStore } from "../../store/store";
import { useT, LANGUAGES, type Lang } from "../../i18n";
import { PALETTES, THEME_MODES, type PaletteId, type ThemeMode } from "../../theme/themes";

export default function SettingsView() {
  const t = useT();
  const { settings, setSettings } = useStore();

  return (
    <div className="settings">
      <section className="panel">
        <h3 className="sec-title">{t("settings.appearance")}</h3>

        <div className="opt">
          <div className="label">{t("settings.theme")}</div>
          <div className="seg">
            {THEME_MODES.map((m: ThemeMode) => (
              <button key={m} className={settings.themeMode === m ? "on" : ""} onClick={() => setSettings({ themeMode: m })}>
                {t(`settings.${m}`)}
              </button>
            ))}
          </div>
        </div>

        <div className="opt">
          <div className="label">{t("settings.palette")}</div>
          <div className="swatches">
            {PALETTES.map((p) => (
              <button
                key={p.id}
                className={"swatch" + (settings.palette === p.id ? " on" : "")}
                title={p.label}
                style={{ background: `linear-gradient(135deg, ${p.accent}, ${p.accent2})` }}
                onClick={() => setSettings({ palette: p.id as PaletteId })}
              />
            ))}
          </div>
        </div>

        <div className="opt">
          <div className="label">{t("settings.language")}</div>
          <select
            className="lang-select"
            value={settings.lang}
            onChange={(e) => setSettings({ lang: e.target.value as Lang })}
          >
            {LANGUAGES.map((l) => (
              <option key={l.id} value={l.id}>{l.label}</option>
            ))}
          </select>
        </div>
      </section>

      <section className="panel">
        <h3 className="sec-title">{t("settings.integrations")}</h3>
        <label className="field" style={{ marginBottom: 12 }}>
          {t("settings.registry")}
          <input placeholder="https://…/registry.json" value={settings.registry} onChange={(e) => setSettings({ registry: e.target.value })} />
        </label>
        <label className="field" style={{ marginBottom: 12 }}>
          {t("settings.aiKey")}
          <input type="password" placeholder="sk-ant-…" value={settings.aiKey} onChange={(e) => setSettings({ aiKey: e.target.value })} />
        </label>
        <label className="field">
          {t("settings.aiModel")}
          <input value={settings.aiModel} onChange={(e) => setSettings({ aiModel: e.target.value })} />
        </label>
        <p className="sec-hint" style={{ marginTop: 10 }}>{t("settings.aiHint")}</p>
      </section>
    </div>
  );
}
