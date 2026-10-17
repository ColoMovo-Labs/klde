# KLDE lock-screen visual study

The lock screen is part of the final mock-first visual freeze. The current
surface is a visual prototype only; it is not a session lock and does not
authenticate a user.

## States

- **Ambient:** large Rubik clock, date, restrained environment line and broad
  wallpaper whitespace.
- **Authentication:** cached blur/depth presentation, user identity, password
  field, input method, accessibility/session actions and power control.
- **Error:** stable authentication geometry with a clear security-critical error;
  no shake animation or friendly voice override.
- **Reduced motion:** the same hierarchy with transitions disabled.
- **Depth/fallback:** pre-authored depth foreground when the cache is valid, or
  the normal wallpaper plus cached/opaque fallback when it is not.

`klde-shell --view lock-screen --lock-state <state>` selects a state. Supported
states are `ambient`, `auth`, `error`, `reduced`, `depth` and `fallback`.

The Display Clock is shared with the desktop hero surface. The lock composition
uses its own content width and edge safe area so the wallpaper's visual mass may
receive an intentional optical offset without moving the clock's reusable token.

## Motion and assets

State transitions are finite and optional. Reduced motion keeps the hierarchy and
removes large transforms. Lock screens consume prepared wallpaper assets from
`WallpaperEffectsBackend`; segmentation and blur are never performed on each
lock or each frame. Missing or failed cache data keeps the normal wallpaper
visible and reports the fallback state.

## Security boundary

`LockScreenSurface` is presentation. A future `SessionLockBackend` must own
session locking, authentication, PAM/KWin integration and failure policy. A
fullscreen Qt window, a mock password field or a screenshot cannot establish a
security boundary. KWin's internal lock support and a Wayland session-lock
protocol remain separate capability probes.
