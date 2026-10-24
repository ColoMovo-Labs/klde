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

Large desktop and lock-preview numerals use unmodified **Rubik**, weight 800,
OFL-1.1. It replaces the earlier Comfortaa Bold proposal, whose strokes were too
light at desktop scale. Rounded corners, fuller counters and a wider numeral
body carry the hierarchy. Fixed digit slots use 0.64 em, the colon uses two discs
in a 0.28 em slot and never blinks. No system font installation or runtime font
download occurs. Chinese interface typography remains independent.

Default desktop has no duplicate display clock. Clock and Focus modes explicitly
opt into a 224 px maximum, constrained by available height/width. A preset name
or font weight alone does not establish acceptance: inspect real cloud captures.

Rubik provenance: [pinned font and original OFL notice](../../assets/fonts/rubik/README.md).
The earlier Comfortaa resource and notice remain for historical compatibility;
it is no longer selected. Google Sans/Product Sans is not bundled.
