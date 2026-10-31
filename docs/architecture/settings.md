# Settings center and persistence

The settings center (`qml/components/SettingsCenter.qml`) is the single place
for owoDE preferences. A category list on the left selects a page on the right.
Pages reuse the content that used to live in separate popups
(`VisualSettingsContent`, `RibbonSettingsContent`, `LanguageInputSettingsContent`,
`WeatherSettingsContent`, `WaydroidSettingsContent`, `WallpaperEffectsSettingsContent`,
`PowerSettingsContent`, `ShortcutSettingsContent`) plus small pages for network,
sound, displays, workspaces and About. Quick Settings keeps the everyday toggles
and links to the settings center.

Older `--view` names (`power-scenes`, `weather`, `language`, `ribbon-settings`,
`wallpaper-effects`, `waydroid`) open the matching page. `--view settings` opens
the first page.

## Keyboard

- The category list takes focus when the center opens. Up/Down change pages.
- Right, Enter or Tab move into the page; Shift+Tab returns.
- Ctrl+Tab / Ctrl+PageDown and Ctrl+Shift+Tab / Ctrl+PageUp change pages from anywhere.
- Esc closes the center. In native sessions the popup host is a layer-shell
  surface with exclusive keyboard interactivity while it is mapped.

## Store

`ShellSettings` (`Shell.settings`) holds a typed schema: each key has a type,
a default and either allowed choices or an integer range. QML writes go through
`setValue()`, which rejects unknown keys and invalid values.

- Preview, Visual Lab and tests keep values in memory only and always start from
  the schema defaults, so captures stay deterministic.
- System/native sessions (`--applications system`) enable
  `~/.config/owode/shell.conf` (`$XDG_CONFIG_HOME/owode`). Values are applied by
  `Shell.restoreSettings()` after `Main.qml` has set the preview state, and later
  changes are written back immediately.
- `meta/version` records the schema version (currently 1). An older or missing
  version is migrated step by step in `ShellSettings::migrate()`; values that no
  longer validate are removed. A file from a newer owoDE is loaded read-only and
  never rewritten. An unparsable file is renamed to `shell.conf.broken-<UTC time>`.

Persisted today: accent, wallpaper, locale and voice, top-bar options, and
per-scene visual overrides (`scenes.<scene>.<option>`, unset means the scene's
own default).
