# owoDE Calculator: initial Lingmo engine port

An independent Qt 6 application, not a shell mock. It uses Lingmo Calculator's
arbitrary-precision engine and an owoDE frontend, with the shell's actual
`MonetPalette.qml`. Runtime is offline; no telemetry, session daemon, platform
theme plugin or LingmoUI installation is required. Use `--dark`, `--locale en`
or `--locale zh_CN`, and `--wallpaper snow|abstract|quiet|kemono` to select the
same authored palettes as the shell. Live shell preference synchronization is
not implemented yet. Windowing uses ordinary Qt Wayland/XCB application roles.

## Provenance and modifications

Upstream: <https://github.com/LingmoOS/lingmo-calculator>, commit
`c2fdb5c80049ce6ffb02571e4bbc64fca1c2366e`.
Verified archive SHA256:
`9560a14d302e797ac0606ea79ced47c8da3bf25de1e00979b9a2b070093bc417`.

- CuteOS/revenmartin's application wrapper: GPL-3.0-or-later. Read for the port;
  the original wrapper is retained in the corresponding-source archive.
- `engine/*`: Ariya Hidayat/SpeedCrunch and GNU bc, Free Software Foundation,
  Philip A. Nelson; original per-file GPL-2.0-or-later notices are preserved.
  The combined adaptation is distributed under GPL-3.0-or-later.
- The fetch script changes two `delete[]` calls to `free` in `hmath.cpp` to match
  `formatFixed`'s allocator. Our wrapper evaluates once, owns its Evaluator with
  RAII, frees formatted results and limits input to bounded basic arithmetic.
- The independent frontend replaces LingmoUI, branding and icon-theme hooks;
  it does not inject a global Qt platform plugin. No Lingmo artwork was copied.

Packages contain the original upstream source archive, the complete port source,
the shared palette, reproducible fetch/patch script and GPL text under
`/usr/share/doc/owode-calculator/`. Cloud artifacts also provide corresponding
source archives next to each binary. Preserve all notices when redistributing.
The fetch script accepts `--archive /path/to/lingmo-calculator-source.tar.gz`
to reconstruct the patched engine offline. The cloud job also configures a new
build from the source installed with the package to check its completeness.

## Cloud validation

`tools/cloud-calculator.sh` fetches, verifies, patches, builds and tests this
optional app in an Ubuntu or Fedora cloud container. It does not run as part
of the default shell build. CMake never downloads dependencies on its own.

The cloud jobs check precedence, parentheses, decimals, Unicode operators,
invalid input and recovery; exercise keyboard entry, Return, keypad clicks and Escape in the real QML
window; render light/dark Chinese/English windows; build
and install a `.deb` or RPM; then start the installed executable. Headless
correctness does not establish interactive Wayland, screen-reader or long-term
daily-use acceptance. Those remain explicit target-host checks.
