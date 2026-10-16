# Shortcuts and keyboard interaction

KLDE adopts useful launcher-first ergonomics while defining its own action IDs,
conflict rules and compositor boundaries. A binding invokes a named action;
configuration never contains executable commands.

## Working prototype

`ShortcutRegistry` is owned by each QML engine's ShellServices instance. It
exposes action metadata and the four bindings below. QML uses application-scoped
Qt Quick Shortcut objects, disables auto-repeat and calls existing UI actions.
Bindings work while a KLDE application window is active. They do not capture
keys globally or close host windows.

| Stable action ID | Default | Action |
| --- | --- | --- |
| `shell.launcher` | `Ctrl+Space` | Toggle the search-first launcher |
| `shell.quick-settings` | `F2` | Toggle Quick Settings |
| `preview.blur-lab` | `Ctrl+Alt+B` | Toggle the owned-content blur laboratory |
| `effects.reduced-motion` | `Ctrl+Alt+R` | Toggle reduced motion |

The preview allows session-only rebinding and reset. Empty input disables one
action. The registry parses Qt `QKeySequence::PortableText`, normalizes bindings
and rejects unknown action IDs, invalid or multi-stroke sequences and duplicate
active assignments. Ordinary keys require Ctrl, Alt or Meta; function keys may
stand alone. This prevents a plain letter or Shift+letter from taking over
launcher typing. Conflicts within this registry are checked; shortcuts already
reserved by the host compositor cannot be discovered by this local mechanism.

`lastError` reports a rejected edit without replacing the working binding.
`bindingsChanged` updates presentation and Shortcut properties. No configuration
file is written, and no existing desktop settings are changed. Persistence and
a full key-capture editor remain future work. Buttons remain available if the
host reserves a chosen sequence.

[Qt's Shortcut contract](https://doc.qt.io/qt-6/qml-qtquick-shortcut.html) defines
application scope as requiring one of the application's windows to be active;
it also documents ambiguity and auto-repeat behavior. That scope is not a global
desktop hotkey registration.

## End-4 reference and KLDE choices

The inspected [end-4 keybind source](https://github.com/end-4/dots-hyprland/blob/2f2a376fdb2ad738bf55f693dd0b474b64bb0ab8/dots/.config/hypr/hyprland/keybinds.lua)
separates compositor dispatch, shell global actions and command fallbacks. It
uses Super release for search, overview/sidebar actions and a shortcut help
surface. A separate [custom keybind file](https://github.com/end-4/dots-hyprland/blob/2f2a376fdb2ad738bf55f693dd0b474b64bb0ab8/dots/.config/hypr/custom/keybinds.lua)
provides a user customization entry. The repository includes a
[GPLv3 license](https://github.com/end-4/dots-hyprland/blob/2f2a376fdb2ad738bf55f693dd0b474b64bb0ab8/LICENSE).
KLDE references the ergonomics and separation of responsibilities; no source,
scripts, command fallback chains or assets are copied.

Do not treat the user's suggested bindings as an exact end-4 map. In the
inspected source Super+V opens clipboard history. KLDE may assign Super+V to
floating toggle as its own deliberate preference. Host conventions, input
methods, accessibility tooling, international layouts and existing bindings need
conflict review before session defaults are finalized.

## Future global registration

Keep three responsibilities separate:

- **Action registry:** allowlisted action IDs, labels, enabled/capability state,
  suggested bindings and user overrides. One action dispatcher owns behavior.
- **Registration adapter:** application-local today; later a portal or specific
  compositor adapter. Report actual accepted bindings, unavailable features and
  conflicts instead of silently claiming success.
- **Window operations:** WindowManagerBackend performs supported workspace/window
  requests. A shortcut adapter does not embed KWin/Hyprland commands in QML.

The [GlobalShortcuts portal](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.GlobalShortcuts.html)
offers session-bound registration, user configuration and activation/deactivation
signals. Availability depends on the running portal backend. Inspect its version,
handle cancellation, session closure and the returned subset of accepted actions;
do not assume the preferred trigger was installed. Version 2 adds a configuration
request. Compositor-specific shell shortcuts may still require a dedicated
adapter. Do not implement a global keylogger, raw input grab or injected key
events as a fallback.

Super alone requires compositor support for distinguishing a tap from a chord.
A future adapter should activate it on release only if no other shortcut or
modifier interaction consumed the press. It must avoid opening the launcher after
Super+number. This is a research/adapter requirement, not current Qt local behavior.

Suggested future session defaults, subject to capability and conflict review:

| Action family | Proposed direction | Gate |
| --- | --- | --- |
| Launcher | Super tap or Super+Space | Accepted global registration; Super tap only with reliable release/chord semantics |
| Switch / move workspace | Super+1..9 / Super+Shift+1..9 | Existing workspace IDs and WindowManagerBackend move capability |
| Toggle active window floating | Super+V | Backend identifies active window and supports floating changes |
| Window close | Super+Q | Explicit active-window close capability; obey application close negotiation |
| Navigation / overview | Super+Tab or Super+W | Decide scope and conflicts before assigning both |
| Quick Settings / notifications | User-configurable dedicated actions | Panel exists and global adapter accepts binding |
| Screenshot / scratchpad | Later allowlisted actions | Portal/compositor capability and interaction design |

Unavailable actions remain visibly unavailable. Do not bind placeholder actions
that do nothing. Future persistent preferences should be versioned, stored under
the XDG config directory, survive default changes and expose reset/export. Tests
must use an isolated temporary configuration root. Session adapters must release
registrations when their owner exits and suppress unsafe actions while locked.
