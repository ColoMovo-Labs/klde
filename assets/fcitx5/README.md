# KLDE Fcitx 5 theme prototypes

Original CC-BY-SA-4.0 theme configuration and SVG artwork, copyright 2026 KLDE
contributors. No upstream theme code or assets were copied. Light/dark variants
use the shell's initial blue/lilac roles, 28-pixel panel silhouettes and emphasized
candidates. Fonts and font size remain Fcitx/user settings, not hidden theme policy.

CMake installs both directories under `/usr/share/fcitx5/themes/`. For a user-only
manual evaluation copy a selected directory to
`~/.local/share/fcitx5/themes/` and select it with Fcitx's configuration tool.
Installation does not enable/restart Fcitx or edit the user's Classic UI config.
Keep the previous theme selected until the new one has been tested in your session.

SVG backgrounds use the Classic UI image/margin contract; solid colors provide
the declared fallback roles. There is no animation, live blur or native candidate
surface implementation. KWin-specific blur is not forced on unknown compositors.
Automatic dynamic color, Power Scene synchronization and interactive candidate
latency/IME acceptance remain later work. CI checks syntax and referenced files;
a source/packaging check is not an Fcitx rendering or typing test.

Format references: [official theme guide](https://fcitx-im.org/wiki/Create_a_new_Fcitx_Theme)
and [upstream configuration schema](https://github.com/fcitx/fcitx5/blob/master/src/ui/classic/theme.h).
