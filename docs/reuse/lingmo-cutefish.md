# LingmoOS and Cutefish reuse strategy

This is a source and license audit, not a compilation or security audit. Every
candidate is pinned in [component-audit.md](component-audit.md) and
[inspected-components.json](inspected-components.json).

## KWin and session components

- LingmoOS `lingmo-kwin` is a deepin-KWin lineage with Qt 6/KF 6 work. Treat it as
a separate `deepin-kwin-v25` engine family, not as upstream KWin 6.
- LingmoOS `lingmo-kwin-plugins` is a GPL-3.0 plugin package with older
Qt5/KDecoration5/KWin assumptions. Reuse behavior and metadata only until a
file-level port is justified.
- Cutefish `kwin-plugins` targets KWin 6/KDecoration3 and contains scripts,
tabbox, decoration and a binary rounded-window effect. Study its boundaries;
rebuild any binary effect against the exact KLDE KWin headers and never install
its global `kwinrc` defaults.
- LingmoOS and Cutefish screen lockers are security-sensitive PAM/X11 research
samples. They do not establish a KLDE Wayland security boundary. KWin internal
locking and a Wayland session-lock protocol are separate capability probes.
- LingmoOS/Cutefish Qt platform/theme plugins are global session hooks. They are
not shell-local theme libraries and must not be globally injected into KLDE.

## Application order

For standalone applications, evaluate LingmoOS first, then Cutefish, then UKUI,
then a KLDE-native implementation only when reuse is unsuitable. Prefer a
packaged external process or narrow UI adaptation over copying a whole desktop
service. The candidate must pass Qt/Framework version, Wayland behavior,
accessibility, translation, maintenance and license checks.

The KLDE shell remains its own codebase. Shared KWin infrastructure does not
justify copying Lingmo or Cutefish branding, session defaults, notification
services or lock authentication.

## Required record for a selected component

Record the upstream URL and exact commit, repository/file licenses, copyright
headers, dependencies, Qt/KF major versions, Wayland/X11 assumptions, selected
reuse method, patch scope, attribution and an exit plan if upstream changes or
stops. Add the component to CI before enabling it in a default session.
