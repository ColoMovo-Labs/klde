# Application ecosystem and reuse decisions

KLDE owns its shell and interaction system. Useful UKUI and LingmoOS applications
can run as independent applications without becoming shell dependencies. The
future distribution can select defaults; upstream KLDE must allow users and
other distributions to choose different applications.

This is a source assessment dated 2026-10-16, not a package certification. No
source, artwork, branding or icon from these projects is included in KLDE.
Building or running these candidates has not yet been validated in KLDE CI.
The KWin/session-specific reuse boundary is tracked separately in
[the LingmoOS/Cutefish audit](../reuse/lingmo-cutefish.md).

## Decision framework

For every app category, make a small decision record with these fields:

1. User task and accessibility requirements, including keyboard use, localization,
   offline behavior and file formats.
2. Exact upstream repository/revision, maintenance signals, security reporting
   route, distro availability and dependency versions. A recent organization page
   is not proof that an individual app is maintained.
3. Integration mode: **use directly**, **theme through supported public APIs**,
   **adapt/fork**, or **behavior reference only**. State who owns updates and
   security fixes. Prefer direct use where it meets the user task.
4. Service boundary: XDG desktop IDs, MIME handlers, portals and documented D-Bus
   interfaces first. Keep optional app integration outside shell presentation.
5. License inventory by file and dependency, including bundled libraries, icons,
   fonts, translations and screenshots. Record notices, source obligations and
   modifications in [the provenance register](../legal/third-party.md) before
   importing anything.
6. Branding review independent of code licensing. Preserve attribution and do not
   imply upstream endorsement. An app used unmodified retains its own identity;
   a future derivative needs an explicit identity and asset review.
7. Ubuntu and Fedora build/runtime evidence, source portability, installation
   paths, Wayland behavior, theme independence and an exit path if upstream stops.

An adaptation needs a concrete advantage over independent reimplementation or
upstream contribution. Do not fork an entire application just to recolor it.
Unknown license provenance, mandatory distro services or unreviewed privileged
helpers block a shipping decision; they do not prevent studying behavior.

## Evidence-bound initial candidates

The links below pin the assessed sources, because default branches and READMEs
can disagree. License summaries describe inspected notices, not every file.

| Category / upstream | Evidence and constraints | Initial KLDE decision |
| --- | --- | --- |
| File manager: UKUI Peony | [README](https://github.com/ukui/peony/blob/3ba0f69d50cb27e635f88926c7d4d9f6c354a616/README.md) describes Qt over GLib/GIO/GVfs and a separate desktop component. [Debian copyright](https://github.com/ukui/peony/blob/3ba0f69d50cb27e635f88926c7d4d9f6c354a616/debian/copyright) lists GPL-3.0-or-later, LGPL-3.0-or-later and MIT/BSD areas. This assessed default branch dates from 2022. | Optional direct external file manager on a compatible host; study file operations, not its desktop ownership. Do not link libpeony into the Qt 6 shell or autostart peony-qt-desktop. |
| Settings: UKUI control center | [README](https://github.com/ukui/ukui-control-center/blob/6730b4605f16bc714288cc7c97b0da4425697257/README.md) lists Qt 5/KF5 and UKUI session, power, screensaver and settings daemons. [Copyright inventory](https://github.com/ukui/ukui-control-center/blob/6730b4605f16bc714288cc7c97b0da4425697257/debian/copyright) includes GPL-2.0-or-later, GPL-3.0-or-later, LGPL-2.1-or-later and BSD portions. | Behavior and compatibility reference. Existing hosts may open their own settings app. Do not adopt its daemon graph as KLDE's settings architecture. |
| File manager: Lingmo | [Current CMake](https://github.com/LingmoOS/lingmo-filemanager/blob/c0ec387386c174db9bb5461071dcb76fd91d3808/CMakeLists.txt) requires Qt 6, KF6 and LingmoUI3; the README still lists older Qt 5 packages. [Application notice](https://github.com/LingmoOS/lingmo-filemanager/blob/c0ec387386c174db9bb5461071dcb76fd91d3808/application.cpp) grants GPL-3.0-or-later. | Evaluate direct use as an external app after its dependency stack is packaged. Reference navigation and file interaction; avoid importing LingmoUI into the KLDE design system. |
| Terminal: Lingmo | [CMake](https://github.com/LingmoOS/lingmo-terminal/blob/276b3a46dab02cd48b530d9875e0bc604c0a55d4/CMakeLists.txt) still requires Qt 5; [README](https://github.com/LingmoOS/lingmo-terminal/blob/276b3a46dab02cd48b530d9875e0bc604c0a55d4/README.md) identifies bundled qmltermwidget. [Main-file notice](https://github.com/LingmoOS/lingmo-terminal/blob/276b3a46dab02cd48b530d9875e0bc604c0a55d4/src/main.cpp) is GPL-3.0-or-later. | Behavior reference now; optional independent app later. A port needs terminal-engine provenance and security maintenance, not just a new QML skin. |
| Calculator: Lingmo | [CMake](https://github.com/LingmoOS/lingmo-calculator/blob/7e11870128d8b2270878c507c70dd58862707fc3/CMakeLists.txt) uses Qt 6 and LingmoUI3. A [GPLv3 license text](https://github.com/LingmoOS/lingmo-calculator/blob/7e11870128d8b2270878c507c70dd58862707fc3/LICENSE) is present; per-file grants still need a full inventory before adaptation. | Small candidate for direct-use evaluation or behavior study. No app selection or source reuse is decided. |

These historical UKUI mirrors do not establish what Ubuntu Kylin 26.04 ships.
Before relying on a UKUI service, inspect the actual distribution package and
introspect its documented interface. Standard NetworkManager, BlueZ, UPower,
PipeWire/WirePlumber, logind, portals and XDG entry APIs remain the preferred
backend targets. A needed UKUI-only service belongs behind an optional adapter
with capability reporting and a clear replacement path.

Image viewing, text editing, archives, software installation, screenshots, system
monitoring, calendars, media and notes remain open selections. Apply the same
framework to UKUI/Lingmo candidates before considering alternatives. Software
centers especially belong in distro packaging policy: KLDE must not assume apt,
dnf, a particular store account or a future KLDE Linux repository.

## Integration and identity boundaries

Application discovery will expose installed desktop entries and MIME associations
through ApplicationBackend. It must not depend on executable names embedded in
QML. Default app preferences are user/distro configuration. A future settings
application will present capability-based backend controls rather than calling
another desktop's privileged helpers or writing sysfs directly.

The current prototype's app IDs and actions remain synthetic. Activating a mock
Files or Terminal item does not install or start one of the assessed applications.
No upstream selection, package availability, license clearance for copied assets,
or compatibility guarantee is implied by this research.
