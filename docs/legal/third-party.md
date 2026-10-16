# Licenses and provenance

## Original material

This baseline is newly authored for KLDE. No UKUI, KWin, GNOME, Quickshell,
end-4 or other shell source code has been copied or derived. No third-party
artwork, icons, fonts, mascot or concept image is included.

| Material | License | Attribution |
| --- | --- | --- |
| Original C++/QML, CMake, CI, tooling and metadata | GPL-3.0-or-later | KLDE contributors; preserve individual notices |
| Original documentation | CC-BY-SA-4.0 | KLDE contributors, file path and revision; identify modifications |
| Original icons and First Light wallpaper | CC-BY-SA-4.0 | KLDE contributors; [asset manifest](../../assets/README.md) and source revision |

`REUSE.toml` supplies per-path SPDX metadata. Full license texts live in
`LICENSES`; `LICENSE` repeats the project code license for repository discovery.
These license texts are legal notices, not imported implementation code.

## External runtime and build dependencies

Qt Core, Gui, Qml, Quick, Quick Controls and their plugins are consumed as Ubuntu
packages. Qt Test and Quick Test are development dependencies. Qt libraries and
plugins retain their upstream licenses and third-party notices; KLDE's license
does not relicense them. We dynamically link distribution Qt. Our own QML module
is embedded; this does not statically bundle Qt itself.

Check the license files of the exact packages before distributing binaries.
[Qt's licensing overview](https://doc.qt.io/qt-6/licensing.html) distinguishes
module licensing and tool exceptions; its
[third-party inventory](https://doc.qt.io/qt-6.8/licenses-used-in-qt.html) describes
additional components. Preserve relevant notices and provide source obligations
for the actual distributed combination. A CMake install archive is not yet a
complete redistribution/compliance package.

CMake, Ninja, GCC/Clang, Python, CircleCI, Weston, Mesa, Xvfb, ccache and REUSE
are build or test tools/services, not copied into the shell. Record their versions
in CI artifacts. Future distribution or code vendoring requires its own review.

## New reuse checklist

For each reused file or asset, record upstream URL, exact revision, author,
SPDX license, modifications and notice location. Confirm compatibility with
GPL-3.0-or-later before adding derived code. GPL-2.0-only code needs particular
care; do not assume “GPL” alone means compatible. For fonts, images and icons,
inspect their own license rather than the repository's headline license.

Project inspiration grants no trademark or artwork rights. KLDE has no affiliation
with Canonical, Ubuntu Kylin, Kylinsoft, Google, KDE, GNOME, Apple or Microsoft.
The KLDE name is a working project identity; this document does not claim a
trademark clearance search has been completed.
