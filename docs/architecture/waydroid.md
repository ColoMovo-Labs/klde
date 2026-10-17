# Optional Waydroid app source

Wayland is the primary product direction. Waydroid is an optional app provider,
never a mandatory shell dependency or installation action. Linux app discovery and
the launcher must continue normally when it is missing, stopped or broken.

## Source and session boundaries

A future app-source contract needs stable source ID, package ID, localized display
name, icon, availability, launch capability and application origin. Use a namespace
such as `android:<package-id>` alongside Linux desktop-file IDs; do not join raw
package names into shell command strings. Keep session readiness separate from
app metadata: a stopped session does not imply the app was uninstalled.

The official [application interface](https://docs.waydro.id/usage/install-and-run-android-applications)
provides listing and launching by Android package ID. A future versioned adapter
can call a supported API or bounded asynchronous `QProcess` argument list for those
operations. The [command reference](https://docs.waydro.id/usage/waydroid-command-line-options)
distinguishes session control from container control. Do not automatically run
initialization, image upgrades, installation or privileged container operations.
Cancellation, startup timeout, unavailable service and stale enumeration need
explicit states. Avoid continuous polling; prefer documented service signals when
available and bounded refresh after user actions/resume otherwise.

Waydroid's [multi-window property](https://docs.waydro.id/usage/waydroid-prop-options)
controls integration with desktop windows and can require a session restart.
This is future capability negotiation, not a setting that this prototype changes.
Window behavior still goes through WindowManagerBackend; do not assume one
compositor's private API or a universal Android-to-Wayland window ID mapping.

## Current mock

`WaydroidBackend` exposes availability, running and indexing preference. Its mock
never probes/starts a process. An explicit Android-ready fixture adds one synthetic
Android Sketch record to ApplicationModel. `origin` distinguishes Android and Linux
in launcher rows. Disabling the source removes that record without affecting Linux
records; a stopped session rejects its simulated launch. No Android packages,
proprietary marks, APKs or account content are included.

## Later bridges

Clipboard, notifications, files, audio and Fcitx integration each need a separately
defined capability and privacy boundary. No silent clipboard synchronization,
notification interception or home-directory sharing is enabled. Validate behavior
with the real Wayland compositor/session before enabling a bridge. Platform
permissions and Android compatibility are not established by a mock launcher row.
