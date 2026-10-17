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
    "bluetooth": '<path d="M18 7V33L29 24L11 11M18 7L29 16L11 29"/>',
    "moon": '<path d="M29 27A12 12 0 0 1 14 10A12 12 0 1 0 29 27Z" fill="#8f91b9" stroke="none"/>',
    "sun": '<circle cx="20" cy="20" r="7" fill="#edc27f"/><path d="M20 5V9M20 31V35M5 20H9M31 20H35M9 9L12 12M28 28L31 31M9 31L12 28M28 12L31 9"/>',
    "volume": '<path d="M7 16H13L20 10V30L13 24H7ZM26 14Q32 20 26 26M30 9Q40 20 30 31"/>',
    "power": '<path d="M20 7V20M12 11A12 12 0 1 0 28 11"/>',
    "leaf": '<path d="M10 30Q5 10 31 9Q32 32 10 30ZM10 30L24 17" fill="#c0d8af"/>',
    "search": '<circle cx="17" cy="17" r="9"/><path d="M24 24L32 32"/>',
    "close": '<path d="M12 12L28 28M12 28L28 12"/>',
    "weather": '<circle cx="25" cy="13" r="9" fill="#e9bd78" stroke="none"/><path d="M9 30C0 29 2 18 10 19C12 10 25 12 27 21C37 19 40 31 30 32H10Z" fill="#f5fcfc" stroke="#a0c0ca"/>',
}
icons.update({'cpu': '<rect x="11" y="11" width="18" height="18" rx="4"/><path d="M16 6V11M24 6V11M16 29V34M24 29V34M6 16H11M6 24H11M29 16H34M29 24H34"/>', 'memory': '<rect x="8" y="12" width="24" height="17" rx="3"/><path d="M13 17V23M20 17V23M27 17V23M13 29V33M20 29V33M27 29V33"/>', 'microphone': '<rect x="16" y="6" width="8" height="18" rx="4"/><path d="M11 19Q11 30 20 30Q29 30 29 19M20 30V35M15 35H25"/>', 'battery': '<rect x="6" y="12" width="26" height="16" rx="4"/><path d="M35 17V23M11 17V23M16 17V23M21 17V23"/>', 'bell': '<path d="M9 28L12 22V16Q12 7 20 7Q28 7 28 16V22L31 28ZM16 33Q20 37 24 33"/>', 'overview': '<rect x="7" y="7" width="10" height="10" rx="2"/><rect x="23" y="7" width="10" height="10" rx="2"/><rect x="7" y="23" width="10" height="10" rx="2"/><rect x="23" y="23" width="10" height="10" rx="2"/>', 'display': '<rect x="5" y="8" width="30" height="21" rx="3"/><path d="M20 29V35M13 35H27"/>', 'info': '<circle cx="20" cy="20" r="13"/><path d="M20 18V27M20 12V13"/>', 'previous': '<path d="M25 9L13 20L25 31"/>', 'next': '<path d="M15 9L27 20L15 31"/>', 'thermometer': '<path d="M16 24V9Q16 4 21 4Q26 4 26 9V24A8 8 0 1 1 16 24ZM21 13V29M30 10H34M30 17H34"/>'})
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

# Original vector compositions, not traced OS wallpapers.
wallpapers = {
    "quiet": '<rect width="1440" height="900" fill="url(#sky)"/><ellipse cx="900" cy="900" rx="1100" ry="510" fill="#accfda" opacity=".35"/>',
    "abstract": '<rect width="1440" height="900" fill="url(#sky)"/><path d="M-160 600C150-250 1050-100 980 430S620 1050 1600 600" fill="none" stroke="url(#flow)" stroke-width="260"/><path d="M-100 610C220-190 1050-90 970 420S700 1010 1600 640" fill="none" stroke="#eaf3ff" opacity=".35" stroke-width="12"/><path d="M-120 640C300-160 1100 10 1020 450S700 1050 1600 710" fill="none" stroke="#b5f1dc" opacity=".35" stroke-width="28"/>',
    "kemono": '<rect width="1440" height="900" fill="url(#sky)"/><path d="M270 900Q40 400 420 170Q440 340 650 470Q840 300 1080 190Q1310 570 1070 900" fill="#b7bfde" opacity=".5"/><path d="M470 900Q1050 510 1190 690Q1280 820 780 950" fill="#cdb9de" opacity=".8"/>'
}
for name, art in wallpapers.items():
    (root / "wallpapers" / (name+".svg")).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="900" viewBox="0 0 1440 900"><defs><linearGradient id="sky" x2=".7" y2="1"><stop stop-color="#cce7f3"/><stop offset="1" stop-color="#ebdcf1"/></linearGradient><linearGradient id="flow" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#55bdd4"/><stop offset=".45" stop-color="#7885e2"/><stop offset=".8" stop-color="#c195df"/><stop offset="1" stop-color="#edbbaf"/></linearGradient></defs>'+art+'</svg>\n')
