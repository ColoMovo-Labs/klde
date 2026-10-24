#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check actual Wayland requests alongside KWin geometry and input assertions."""
import json
from pathlib import Path
import re
import sys

output = Path(sys.argv[1])
expected = {
    'wallpaper': (0, 15, -1, 0),
    'ribbon': (2, 13, None, 0),
    'dock': (2, 14, 0, 0),
    'popup': (3, 15, -1, 1),
}


def inspect(log, label):
    roles = {}
    namespaces = {'desktop': ['wallpaper'], 'dock': ['ribbon', 'dock'], 'on-screen-display': ['popup']}
    for line in log.splitlines():
        if 'get_layer_surface(' not in line:
            continue
        match = re.search(r'new id (zwlr_layer_surface_v1[@#]\d+).*?,\s*(\d+),\s*"(desktop|dock|on-screen-display)"', line)
        if not match:
            continue
        identifier, layer, namespace = match.groups()
        requests = '\n'.join(entry for entry in log.splitlines() if identifier + '.' in entry)
        candidates = [role for role in namespaces[namespace]
                      if expected[role][0] == int(layer) and f'.set_anchor({expected[role][1]})' in requests]
        if len(candidates) != 1:
            raise SystemExit(f'{label}: unrecognized layer/namespace/anchor combination: {line}')
        roles.setdefault(candidates[0], []).append(identifier)
    for role, (_, anchor, zone, keyboard) in expected.items():
        if role not in roles:
            raise SystemExit(f'{label}: missing actual Wayland layer role: {role}')
        requests = '\n'.join(line for line in log.splitlines()
                             if any(identifier + '.' in line for identifier in roles[role]))
        for method, value in [('set_anchor', anchor), ('set_keyboard_interactivity', keyboard)]:
            if f'.{method}({value})' not in requests:
                raise SystemExit(f'{label}: missing {role} {method}({value})')
        if zone is None:
            if not re.search(r'\.set_exclusive_zone\([1-9][0-9]*\)', requests):
                raise SystemExit(f'{label}: ribbon did not reserve space')
        elif f'.set_exclusive_zone({zone})' not in requests:
            raise SystemExit(f'{label}: missing {role} exclusive zone {zone}')
        if '.ack_configure(' not in requests:
            raise SystemExit(f'{label}: no configure acknowledgement for {role}')
    if re.search(r'protocol error|error 71|Failed to initialize layer-shell integration', log, re.I):
        raise SystemExit(f'{label}: compositor protocol failure')
    return roles


log = (output / 'native-test.log').read_text()
roles = inspect(log, 'interactive test')
if 'get_toplevel(' not in log or 'set_input_region(' not in log:
    raise SystemExit('Missing ordinary application or input region protocol evidence')
main = (output / 'native-main.log').read_text()
main_roles = inspect(main, 'actual shell CLI')
if 'owoDE native roles attached:' not in main or 'QML ' in main or 'Binding loop' in main:
    raise SystemExit('The actual shell CLI failed native startup without QML warnings')
if 'get_toplevel(' in main:
    raise SystemExit('The native shell CLI created an ordinary application toplevel')
(output / 'protocol-evidence.json').write_text(json.dumps({
    'revision': (output / 'source-commit.txt').read_text().strip(),
    'testWaylandRoles': roles,
    'actualShellWaylandRoles': main_roles,
    'normalQtClient': True,
    'inputAndFocus': 'See native-tests.xml, KWin snapshots and native-test.log',
    'renderer': 'See kwin-support.txt; cloud Xvfb runs use Mesa software',
    'hardwarePerformanceBenchmark': False,
    'hostSessionChanged': False,
    'scope': 'Single output integration; not daily-use acceptance',
}, indent=2) + '\n')
print('Native role, input and normal-client protocol evidence verified')
