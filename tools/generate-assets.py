#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Regenerate KLDE's original geometric SVG icons and First Light wallpaper."""
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "assets"
icons = {
    "klde": '<path d="M8 27Q6 18 9 8Q16 11 20 17Q27 11 32 9Q34 19 31 27Q21 35 8 27Z" fill="#4a47cb"/><path d="M12 19Q19 24 28 19L25 27H16Z" fill="#f6e2c6"/><circle cx="15" cy="19" r="1.4" fill="white"/><circle cx="25" cy="19" r="1.4" fill="white"/>',
    "folder": '<path d="M7 13H17L21 17H33V30H7Z" fill="#f0c887"/><path d="M7 19H33L30 31H10Z" fill="#dfa75b"/>',
    "globe": '<circle cx="20" cy="20" r="12"/><ellipse cx="20" cy="20" rx="5" ry="12"/><path d="M9 16H31M9 24H31"/>',
    "terminal": '<rect x="7" y="10" width="26" height="22" rx="5" fill="#423b80" stroke="none"/><path d="M12 17L16 21L12 25M21 26H27" stroke="#f4fbfa"/>',
    "note": '<path d="M11 7H26L31 13V33H11Z" fill="#fffdf5"/><path d="M16 18H26M16 23H26M16 28H23"/>',
    "music": '<path d="M17 27V12L30 9V24M17 16L30 13"/><ellipse cx="13" cy="28" rx="4" ry="3" fill="#477d7a"/><ellipse cx="26" cy="25" rx="4" ry="3" fill="#477d7a"/>',
    "settings": '<circle cx="20" cy="20" r="8"/><circle cx="20" cy="20" r="3"/><path d="M20 7V11M20 29V33M7 20H11M29 20H33M11 11L14 14M26 26L29 29M11 29L14 26M26 14L29 11"/>',
    "wifi": '<path d="M7 15Q20 4 33 15M12 21Q20 14 28 21M17 26Q20 23 23 26"/><circle cx="20" cy="31" r="1.8" fill="#363b87" stroke="none"/>',
    "bluetooth": '<circle cx="13" cy="14" r="5"/><circle cx="27" cy="26" r="5"/><path d="M17 17L23 23M23 12H31V18M9 22V29H17"/>',
    "moon": '<path d="M29 27A12 12 0 0 1 14 10A12 12 0 1 0 29 27Z" fill="#8f91b9" stroke="none"/>',
    "sun": '<circle cx="20" cy="20" r="7" fill="#edc27f"/><path d="M20 5V9M20 31V35M5 20H9M31 20H35M9 9L12 12M28 28L31 31M9 31L12 28M28 12L31 9"/>',
    "volume": '<path d="M7 16H13L20 10V30L13 24H7ZM26 14Q32 20 26 26M30 9Q40 20 30 31"/>',
    "power": '<path d="M20 7V20M12 11A12 12 0 1 0 28 11"/>',
    "leaf": '<path d="M10 30Q5 10 31 9Q32 32 10 30ZM10 30L24 17" fill="#c0d8af"/>',
    "search": '<circle cx="17" cy="17" r="9"/><path d="M24 24L32 32"/>',
    "close": '<path d="M12 12L28 28M12 28L28 12"/>',
    "weather": '<circle cx="25" cy="13" r="9" fill="#e9bd78" stroke="none"/><path d="M9 30C0 29 2 18 10 19C12 10 25 12 27 21C37 19 40 31 30 32H10Z" fill="#f5fcfc" stroke="#a0c0ca"/>',
}
for name, content in icons.items():
    for suffix in ("", "-light"):
        ink = "#363b87"
        artwork = content
        if suffix:
            if name not in ("folder", "note", "terminal", "weather"):
                ink = "#f3f0ff"
            artwork = (content.replace("#363b87", "#f3f0ff")
                       .replace("#4a47cb", "#c6c0ff")
                       .replace("#477d7a", "#b6dcd6"))
            if name == "klde":
                artwork = artwork.replace('fill="white"', 'fill="#28205e"')
        target = root / "icons" / f"{name}{suffix}.svg"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40">\n'
                          f'<g fill="none" stroke="{ink}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">'
                          + artwork + '</g>\n</svg>\n')

wallpaper = root / "wallpapers" / "first-light.svg"
wallpaper.parent.mkdir(parents=True, exist_ok=True)
wallpaper.write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="900" viewBox="0 0 1440 900">
<defs>
  <linearGradient id="sky" x2="0" y2="1"><stop stop-color="#dceaff"/><stop offset="1" stop-color="#ede4ff"/></linearGradient>
  <linearGradient id="near" x2="0.4" y2="1"><stop stop-color="#a0b8ef"/><stop offset="1" stop-color="#ccc9f4"/></linearGradient>
</defs>
<rect width="1440" height="900" fill="url(#sky)"/>
<circle cx="1120" cy="214" r="140" fill="#f8e4ca" opacity="0.6"/>
<circle cx="1120" cy="214" r="90" fill="#ffeacc"/>
<path d="M430 648L923 238Q944 217 966 245L1440 684V900H400Z" fill="#c8d8f3"/>
<path d="M816 340L923 238Q944 217 966 245L1070 367L975 336L949 366L915 328L879 367Z" fill="#f9fbf5"/>
<path d="M0 716L341 342Q372 307 406 347L834 769L1000 900H0Z" fill="#b3c9ed"/>
<path d="M262 430L341 342Q372 307 406 347L515 472L406 430L374 458L339 410L299 455Z" fill="#f7fbf9"/>
<path d="M374 343L406 347L834 769L570 691L421 482Z" fill="#9fb2e6" opacity="0.65"/>
<path d="M0 702Q290 592 573 722Q795 831 1052 691Q1270 575 1440 674V900H0Z" fill="url(#near)"/>
<path d="M0 838Q249 715 516 831Q837 951 1111 817Q1318 736 1440 787V900H0Z" fill="#d4dcfa"/>
</svg>
''')
