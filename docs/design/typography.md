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
Display clocks use the shared family with medium weight; every row must
permit elision or wrapping under text scaling. Only two weights (~18 MB) are
embedded. This increases source/package size but avoids runtime downloads.
Full provenance and OFL notices: [font assets](../../assets/fonts/README.md).
