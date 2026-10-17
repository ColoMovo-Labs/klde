# Licenses and provenance

## Original material

This baseline is newly authored for KLDE. No UKUI, KWin, GNOME, Quickshell,
end-4, LingmoOS or other shell source code has been copied or derived. No third-party
artwork, icons, mascot or concept image is included. The separately licensed
Glow Sans font evaluation is documented below.

| Material | License | Attribution |
| --- | --- | --- |
| Original C++/QML, CMake, CI, tooling and metadata | GPL-3.0-or-later | KLDE contributors; preserve individual notices |
| Original documentation | CC-BY-SA-4.0 | KLDE contributors, file path and revision; identify modifications |
| Original icons and First Light wallpaper | CC-BY-SA-4.0 | KLDE contributors; [asset manifest](../../assets/README.md) and source revision |

`REUSE.toml` supplies per-path SPDX metadata. Full license texts live in
`LICENSES`; `LICENSE` repeats the project code license for repository discovery.
These license texts are legal notices, not imported implementation code.

## External runtime and build dependencies

Qt Core, Gui, DBus, Network, Qml, Quick, Quick Controls and their plugins are consumed as Ubuntu
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

The [application assessment](../architecture/apps.md) and
[shortcut study](../architecture/shortcuts.md) record pinned research references;
they import no implementation or assets. Qt Network is used for the optional
[uapis.cn adapter](../architecture/weather.md). Provider observations and data
rights are separate from KLDE's code and artwork licenses; no real responses
are included in test fixtures. Distribution of an enabled service still requires
review of the current provider terms and source-data rights.

For each reused file or asset, record upstream URL, exact revision, author,
SPDX license, modifications and notice location. Confirm compatibility with
GPL-3.0-or-later before adding derived code. GPL-2.0-only code needs particular
care; do not assume “GPL” alone means compatible. For fonts, images and icons,
inspect their own license rather than the repository's headline license.

Project inspiration grants no trademark or artwork rights. KLDE has no affiliation
with Canonical, Ubuntu Kylin, Kylinsoft, Google, KDE, GNOME, Apple or Microsoft.
The KLDE name is a working project identity; this document does not claim a
trademark clearance search has been completed.

## Language and input additions

The embedded English/Chinese catalogs are original GPL-licensed UI data. Sparse
Cute catalogs contain no executable code. Original Fcitx light/dark theme assets
are CC BY-SA 4.0 under the asset metadata; theme syntax was studied from upstream
documentation/schema without copying its implementation or artwork. See
[the theme manifest](../../assets/fcitx5/README.md). The theme is installed with
the preview but not automatically enabled. Fcitx itself is not vendored or linked;
only read-only session-bus service availability is observed.

Ubuntu/Fedora runtime font dependencies remain separate distribution packages:
Noto CJK (OFL-1.1) and Noto Color Emoji (upstream notices include OFL-1.1 and
Apache-2.0). Those fallback files are not bundled. Glow Sans is embedded separately under
OFL-1.1 as described below. Record exact
package notices when producing a complete distribution image.

## Wêlai Glow Sans SC

The Visual Lab embeds unmodified Normal Regular and Medium from v0.93,
copyright 2020 Celestial Phineas, licensed under SIL OFL 1.1. The complete
notice is in `assets/fonts/glow-sans/OFL.txt`, also installed with the application.
See [font provenance](../../assets/fonts/README.md) for source commit and hashes.
No MIT-licensed upstream font-building code is copied. No MiSans is bundled.

Comfortaa Bold: unmodified Fedora 3.105 package asset, OFL-1.1; original notices,
reserved name and FONTLOG retained. See [font provenance](../../assets/fonts/README.md).
The project bundles no proprietary Google display font. New wallpaper layer
studies are original vectors, not output copied from a segmentation model.
