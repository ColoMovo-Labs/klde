# Visual Lab typography

Wêlai Glow Sans SC v0.93 Normal Regular and Medium are the primary application
fonts for Chinese and Latin. The upstream font combines Source Han Sans,
Fira Sans and Raleway; this provides a companion Latin design without adding
another family. This is a static-font evaluation, not a variable-font claim.
Qt FontLoader registers the bundled files only for this process. Nothing is
installed in the user's font directories.

Noto Sans CJK SC / Source Han Sans SC remain distribution fallbacks. Missing
glyphs rely on Qt/fontconfig fallback; CJK coverage and punctuation need native
speaker review. Upstream's old/archived release and known glyph limitations
are reasons to evaluate, not to promise universal script coverage. Monospace
content retains the system monospace family.

Chinese labels use 15 px, captions 13 px, body 16 px. Latin labels use 14 px,
captions 12 px. Density adjusts control geometry, never shrinks caption text.
Ordinary UI remains on Glow Sans; every row must
permit elision or wrapping under text scaling. Only two weights (~18 MB) are
embedded. This increases source/package size but avoids runtime downloads.
Full provenance and OFL notices: [font assets](../../assets/fonts/README.md).

## Dedicated display clock

Large desktop and future lock-screen numerals use unmodified **Comfortaa Bold**,
OFL-1.1, through `displayClockFont`, `displayClockWeight` and
`displayClockTracking`. This rounded display face is not applied to menus, body
text or the compact ribbon. Fixed digit slots balance numeral widths; the colon
uses two aligned discs and never blinks. A working clock uses the same family at
smaller emphasis; Ambient uses the display scale. No Google Sans/Product Sans is
bundled. Final weight, numeral proportions and colon alignment require cloud
captures and visual review; a font choice alone is not acceptance.
