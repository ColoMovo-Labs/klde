# Night color roles

Night uses its own palette rather than darkening a day scene uniformly.

| Role | Light | Night |
| --- | --- | --- |
| Background | `#edf2ff` | `#10182b` |
| Surface | `#f9faff` | `#19283e` |
| Container | `#e8eaff` | `#263650` |
| Elevated | White | `#223148` |
| Main ink | `#20264d` | `#eef3ff` |
| Secondary ink | `#566287` | `#bacbe1` |
| Outline | `#747fa6` | `#8fa5c5` |
| Default accent | Wallpaper-derived preset | Soft teal `#99d1c8` |
| Shadow | Violet `#292e6b` | Deep ink `#070e20` |

These are `Tokens` roles. Icons select the existing light-ink variants on dark
surfaces. Low-opacity borders separate surfaces; accents remain sparse. The
landscape's time keeps a local contrast gradient in all six conditions.

`first-night.svg` is an original night mountain composition with quiet stars and
a crescent. Abstract, Quiet and Kemono have controlled pre-authored night color
variants. Wallpaper selection remains meaningful. Mock cache studies also have
night counterparts; no live color filter or blur pipeline runs to produce them.
The old global dark-wallpaper veil is removed. The light lock-preview dim layer
remains local to that disclosed mock surface.

Qt token tests cover primary-action contrast for both themes and all accents;
actual desktop captures check the wider visual hierarchy. These checks do not
replace real display, screen reader or user accessibility evaluation.
