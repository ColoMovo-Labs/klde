# Licenses and provenance

## Original material

The original shell baseline was newly authored for KLDE. No UKUI, KWin, GNOME,
Quickshell, end-4 or Lingmo shell implementation is embedded in that baseline.
The optional Lingmo Calculator engine port is documented separately below. No third-party
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

### Optional KF6 application integration

`DesktopApplicationBackend` dynamically links distribution KService, KConfig and
KIOGui. No implementation code, application branding or icons are copied from
those projects. Plasma Shell is not a runtime prerequisite.
The inspected [KService public header](https://github.com/KDE/kservice/blob/master/src/services/kservice.h)
is LGPL-2.0-or-later; the inspected
[ApplicationLauncherJob header](https://github.com/KDE/kio/blob/master/src/gui/applicationlauncherjob.h)
offers LGPL-2.0-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL.
The LGPL-3.0 option is compatible with the project's GPL-3.0-or-later combination.
The distribution libraries retain their own notices/licenses; our SPDX metadata
does not relicense them. Record the exact package versions and notices from cloud
artifacts for each binary distribution. These header observations are not a claim
that every file in all KDE Frameworks has the same license.

### Optional Lingmo Calculator engine

The [calculator provenance record](../../apps/calculator/README.md) identifies
LingmoOS `lingmo-calculator` commit `c2fdb5c80049ce6ffb02571e4bbc64fca1c2366e`,
the archive hash, original CuteOS/revenmartin, Ariya Hidayat/SpeedCrunch and GNU bc
notices, and the exact adaptation. The cloud-only fetch script preserves all
headers, corrects two allocator mismatches, and compiles only its engine into
an independent owoDE application. GPL-2.0-or-later engine files are combined
under GPL-3.0-or-later; the original GPL terms/notices remain in corresponding
source. Packages carry the original source archive and complete reproducible
adaptation; no Lingmo artwork, Qt platform plugin or session component is copied.
Compilation and runtime acceptance are tracked by the dedicated Ubuntu/Fedora
cloud jobs, not inferred from this source/license inspection.

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

### Test-only KWin input protocol

`tests/native/protocols/fake-input.xml` is copied without modification from
[KDE plasma-wayland-protocols](https://github.com/KDE/plasma-wayland-protocols/blob/1db07441870d54157e937674b99380a7dcc0fb32/src/protocols/fake-input.xml),
commit `1db07441870d54157e937674b99380a7dcc0fb32`. Copyright 2015 Martin
Gräßlin, LGPL-2.1-or-later; original notices and the full license are retained.
Wayland-scanner generates its client binding in the cloud build directory.
Only the isolated native test executable links this protocol. It is neither a
production input backend nor installed with the shell. KWin/LayerShellQt source
was inspected to understand public APIs; no compositor implementation was copied.

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

## Rubik display correction

The unmodified `Rubik[wght].ttf` is from Google Fonts commit
`8b0a1d0f5983c89bc2b93f1b5fb55f9e252744b5`, copyright 2015 The Rubik Project Authors,
SIL OFL 1.1. [Exact provenance and SHA-256](../../assets/fonts/rubik/README.md),
original OFL, upstream metadata and source history are retained. Its notice is
installed as `Rubik-OFL.txt` and verified in the clean runtime packaging job.
This is an open font distribution, not permission to distribute Google Sans or
use Google's marks. New landscape and night assets are original CC BY-SA 4.0
vectors. No reference screenshot pixels or third-party illustration is copied.

## Welcome guide reference

`assets/welcome/klde-guide-wave.png` and its neutral fallback are transparent
guide illustrations derived from a user-provided mint fox character reference
for the KLDE Welcome mock. They are replaceable artwork for the visual phase.
Before a public release,
record the final character author's permission and asset license here; do not
assume that the reference screenshot alone grants redistribution rights.

`assets/welcome/klde-guide-hero-v2.png` is an original transparent character
variant generated from the same user-provided reference for the KLDE OOBE hero
composition. It is kept as a separate versioned asset until the project owner
records the final authorship and redistribution terms.

`assets/welcome/klde-wordmark.svg` contains editable vector paths. The path
shapes were developed from the SIL Open Font License 1.1 Iansui reference and
then adjusted into a KLDE slanted, heavier treatment; the source font is not
shipped. Preserve the OFL attribution when redistributing derived artwork.

## GNOME/KDE runtime compatibility checks

Fedora compatibility jobs install distribution GNOME Calculator and KCalc
packages with their unmodified dependency and license metadata. Their code and
branding are not copied into owoDE. Running them alongside the shell is a
compatibility test, not an application port or an affiliation claim. The new
logo is generated at the owner request; provenance and prompt are recorded in
assets/branding/README.md and logo-prompt.md.
