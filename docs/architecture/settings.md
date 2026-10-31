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

## Dock and top-bar space

`dock.mode` selects how the native dock shares the bottom edge:

- `smart` (default): the dock hides while a window on the active workspace
  overlaps the dock's resting rectangle. Overlap uses KWin frame geometry from
  `kwin-state.js` (coalesced to one snapshot per 150 ms during moves) through
  `WindowManagerBackend::windowOverlaps()`. Windows without known geometry,
  including every mock window, never count.
- `reserve`: the dock surface keeps an exclusive zone equal to its height
  (dock plus margins), so maximized windows stop above it.
- `hidden`: the dock stays hidden.

A hidden dock comes back while the pointer is on the bottom edge or the dock,
for 1.6 s after Super is pressed while the shell has keyboard focus, and after
the launcher closes. Showing and hiding is one finite spring on `reveal`;
nothing repaints after it settles. While hidden the surface's input region is a
4 px strip on the screen edge (`dockEdgeTrigger`); while revealed by the pointer
the strip bridges the gap up to the dock so the pointer never falls through.

The top bar reserves its resting height (`StatusRibbon.restingHeight` plus
margins), not its current height, so an expanded System Island no longer
pushes windows down. Both zones are set from QML through
`Shell.surface.setExclusiveZone()`.
