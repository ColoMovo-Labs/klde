#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check real Wayland request logs, in addition to KWin/Qt interaction tests."""
import json
from pathlib import Path
import re
import sys

output = Path(sys.argv[1])
log = (output / "native-test.log").read_text()
roles = {}
layers = {"wallpaper": 0, "ribbon": 2, "dock": 2, "popup": 3}
for line in log.splitlines():
    if "get_layer_surface(" in line:
        match = re.search(r"new id (zwlr_layer_surface_v1[@#]\d+).*\"owode-(wallpaper|ribbon|dock|popup)\"", line)
        if match:
            if not re.search(rf",\s*{layers[match[2]]},\s*\"owode-{match[2]}\"", line):
                raise SystemExit(f"Incorrect actual layer for {match[2]}")
            roles.setdefault(match[2], []).append(match[1])
expected = {"wallpaper": (15, -1, 0), "ribbon": (13, None, 0), "dock": (14, 0, 0), "popup": (15, -1, 1)}
for role, (anchor, zone, keyboard) in expected.items():
    if role not in roles:
        raise SystemExit(f"Missing actual Wayland layer role: {role}")
    requests = "\n".join(line for line in log.splitlines() if any(identifier + "." in line for identifier in roles[role]))
    for method, value in [("set_anchor", anchor), ("set_keyboard_interactivity", keyboard)]:
        if f".{method}({value})" not in requests:
            raise SystemExit(f"Missing {role} {method}({value})")
    if zone is None:
        if not re.search(r"\.set_exclusive_zone\([1-9][0-9]*\)", requests):
            raise SystemExit("Ribbon did not reserve space")
    elif f".set_exclusive_zone({zone})" not in requests:
        raise SystemExit(f"Missing {role} exclusive zone {zone}")
    if ".ack_configure(" not in requests:
        raise SystemExit(f"No configure acknowledgement for {role}")
if "get_toplevel(" not in log or "set_input_region(" not in log:
    raise SystemExit("Missing ordinary application or input region protocol evidence")
main = (output / "native-main.log").read_text()
if "owoDE native roles attached:" not in main or "QML " in main or "Binding loop" in main:
    raise SystemExit("The actual shell CLI failed native startup without QML warnings")
(output / "protocol-evidence.json").write_text(json.dumps({
    "revision": (output / "source-commit.txt").read_text().strip(),
    "actualWaylandRoles": roles,
    "layers": layers,
    "normalQtClient": True,
    "inputAndFocus": "See native-tests.xml, KWin snapshots and native-test.log",
    "renderer": "Nested X11 KWin over Xvfb/Mesa software; correctness only",
    "hostSessionChanged": False,
    "scope": "Single output cloud integration; not daily-use or hardware acceptance",
}, indent=2) + "\n")
print("Native role, input and normal-client protocol evidence verified")
