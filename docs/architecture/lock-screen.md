# Lock-screen architecture boundary

The current `LockScreenSurface` is a mock visual state machine. It deliberately
has no credentials, PAM calls, privileged helper or session-lock authority.

## Presentation contract

The surface consumes:

- wallpaper choice and prepared cached assets;
- Display Clock/time/date models;
- weather/environment summary with explicit mock provenance;
- locale/input display state;
- visual state (`ambient`, `auth`, `error`, `reduced`, `depth`, `fallback`).

It does not decide whether the session is locked. The visual state can be driven
by a future `SessionLockBackend` after the backend confirms the session state.

## Future backend

A real backend must probe the KWin engine family, internal lock-screen/session
integration and supported Wayland session-lock protocol. Authentication remains
separate from wallpaper and QML state. On lock failure or backend disconnect, the
session state remains security-owned; the shell must not silently downgrade to a
fullscreen preview.

LingmoOS and Cutefish lock-screen code is research material only. Their audited
PAM/X11 paths do not establish KLDE Wayland security. See
[`docs/architecture/kwin-adapter.md`](kwin-adapter.md) and
[`docs/reuse/lingmo-cutefish.md`](../reuse/lingmo-cutefish.md).

## Cached wallpaper flow

`original wallpaper -> prepared foreground/background -> cached lock blur ->
LockScreenSurface`.

The cache has generation and validity metadata. The surface selects a prepared
asset or an opaque/normal fallback; it never runs segmentation or a large blur
pipeline in response to a lock event.
