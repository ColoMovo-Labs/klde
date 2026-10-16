#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Structural validation only; actual candidate UI requires interactive testing."""
import configparser
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1] / "assets/fcitx5"
for name in ("klde-expressive-light", "klde-expressive-dark"):
    folder = root / name
    config = configparser.ConfigParser(interpolation=None, strict=True)
    config.optionxform = str
    config.read_string((folder / "theme.conf").read_text())
    for section in ("Metadata", "InputPanel", "InputPanel/Background", "Menu/Background"):
        if not config.has_section(section):
            raise ValueError(f"Missing {section} in {name}")
    for section in config.sections():
        if "Image" in config[section]:
            image = folder / config[section]["Image"]
            if image.parent != folder or image.suffix != ".svg":
                raise ValueError(f"Unexpected image reference: {image}")
            svg = ET.parse(image).getroot()
            if svg.tag != "{http://www.w3.org/2000/svg}svg" or "viewBox" not in svg.attrib:
                raise ValueError(f"Invalid SVG: {image}")
        for key in ("Left", "Right", "Top", "Bottom"):
            if key in config[section] and not 0 <= int(config[section][key]) <= 64:
                raise ValueError(f"Invalid margin in {name}: {section}.{key}")
    if config["InputPanel"]["EnableBlur"] != "False":
        raise ValueError("The unvalidated prototype must retain its no-blur default")
print("Validated two original Fcitx theme prototypes (structure only)")
