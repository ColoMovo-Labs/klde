# ADR 0010: Configurable named shortcut actions

Status: accepted for the application preview; global adapters deferred.

## Context

The preview has several keyboard entry points. Future session shortcuts must
support launcher-first interaction without binding the shell to one compositor.
Hardcoded QML chords and command strings would make remapping, conflict handling
and accessibility difficult. Qt application shortcuts do not provide global
Wayland registration.

## Decision

Add a per-engine ShortcutRegistry with stable allowlisted action IDs and typed
bindings for launcher, Quick Settings, blur preview and reduced motion. Use Qt
PortableText parsing and canonicalization. Allow disable/reset; reject unknown
IDs, invalid/multi-stroke bindings and duplicate active assignments. Require a
command modifier for ordinary keys to preserve search typing. Changes apply only
to this process session.

QML remains presentation and action wiring. Future global registration belongs
to a capability-reporting portal/compositor adapter. WindowManagerBackend owns
window and workspace operations. Super-tap detection, persistence and global
registration are deferred until they can be implemented and validated honestly.

## Consequences

Users can experiment without altering host desktop shortcuts or files. Unit
contracts cover independent instances, invalid/conflicting edits, disable and
reset. CircleCI remains the build/test authority. Host-reserved sequences may
prevent delivery, so the UI retains buttons and describes the local scope.
The preview does not claim that a configured sequence is globally registered.

## Alternatives considered

Hardcoded per-component bindings are easy initially but duplicate policy. A
Hyprland-only config would choose a compositor prematurely. Global raw input
capture introduces unnecessary permissions and security risk. Executable command
bindings would turn a small UI preference into a process-execution interface.

See [shortcut architecture](../architecture/shortcuts.md) and its pinned primary
references for the end-4 ergonomics study and portal boundary.
