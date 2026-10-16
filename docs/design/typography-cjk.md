# CJK typography

Use distribution fonts, not copied font binaries. Noto Sans CJK SC is the initial
Simplified Chinese preference; Qt/fontconfig supplies fallback for Latin, other
CJK and symbols. English keeps the system sans. Noto CJK is available under
OFL-1.1: [upstream](https://github.com/notofonts/noto-cjk) and
[Fedora's variable package](https://packages.fedoraproject.org/pkgs/google-noto-sans-cjk-vf-fonts/google-noto-sans-cjk-vf-fonts/fedora-44.html).
Ubuntu CI/package runtime uses fonts-noto-cjk; Fedora uses
 google-noto-sans-cjk-vf-fonts. No font is bundled or relicensed by KLDE.

Chinese glyph density needs its own caption/label sizing and comfortable line
height. Prefer real Medium/DemiBold weights when available; test variable-font
rasterization rather than assuming it. Keep mixed Latin/CJK baselines and numbers
balanced. Wrap prose and elide secondary metadata, never essential confirmation.
Use QLocale dates/numbers and correct Chinese punctuation; do not insert spaces
between arbitrary Chinese glyphs to imitate Latin rhythm.

Review Simplified Chinese and English at 100/150/200%, long app names, full-width
punctuation, mixed numbers, dark/light/translucent surfaces and narrow windows.
Terminal/IDE integration should evaluate Noto Sans Mono CJK plus a compatible
Latin monospace without changing shell body typography. These are acceptance
procedures, not claims that all hardware/font configurations are validated.
