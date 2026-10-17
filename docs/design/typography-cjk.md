# CJK typography

The Visual Lab evaluates bundled Wêlai Glow Sans SC Regular/Medium as the primary
family; see [typography and provenance](typography.md). Distribution Noto Sans
CJK SC / Source Han Sans SC provide fallback through Qt/fontconfig. Noto CJK is
available under OFL-1.1: [upstream](https://github.com/notofonts/noto-cjk).
Ubuntu CI/package runtime keeps fonts-noto-cjk; Fedora keeps
google-noto-sans-cjk-vf-fonts. No fallback font is relicensed by KLDE.

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
