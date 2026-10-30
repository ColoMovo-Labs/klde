#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check actual Wayland requests alongside KWin geometry and input assertions."""
import json
from pathlib import Path
import re
import sys

expected = {
    'wallpaper': (0, 15, -1, 0),
    'ribbon': (2, 13, None, 0),
    'dock': (2, 14, 0, 0),
    'popup': (3, 15, -1, 1),
}


def inspect(log, label):
    # Object numbers are recycled after destroy, including between QML engines.
    # Validate each lifetime independently; never union requests by numeric ID.
    active = {}
    instances = []
    namespaces = {'desktop': ['wallpaper'], 'dock': ['ribbon', 'dock'], 'on-screen-display': ['popup']}
    for line in log.splitlines():
        if 'get_layer_surface(' in line:
            match = re.search(r'new id (zwlr_layer_surface_v1[@#]\d+).*?,\s*(\d+),\s*"(desktop|dock|on-screen-display)"', line)
            if match:
                identifier, layer, namespace = match.groups()
                if identifier in active:
                    raise ValueError(f'{label}: live layer object ID reused: {identifier}')
                instance = {'id': identifier, 'layer': int(layer), 'namespace': namespace, 'requests': []}
                active[identifier] = instance
                instances.append(instance)
        for identifier, instance in list(active.items()):
            if identifier + '.' in line:
                instance['requests'].append(line)
                if identifier + '.destroy()' in line:
                    del active[identifier]
    roles = {}
    for instance in instances:
        requests = '\n'.join(instance['requests'])
        candidates = [role for role in namespaces[instance['namespace']]
                      if expected[role][0] == instance['layer'] and f'.set_anchor({expected[role][1]})' in requests]
        if len(candidates) != 1:
            raise ValueError(f'{label}: unrecognized layer/namespace/anchor lifetime: {instance["id"]}')
        role = candidates[0]
        roles.setdefault(role, []).append(instance['id'])
        _, anchor, zone, keyboard = expected[role]
        for method, value in [('set_anchor', anchor), ('set_keyboard_interactivity', keyboard)]:
            if f'.{method}({value})' not in requests:
                raise ValueError(f'{label}: missing {role} {method}({value})')
        if zone is None:
            if not re.search(r'\.set_exclusive_zone\([1-9][0-9]*\)', requests):
                raise ValueError(f'{label}: ribbon did not reserve space')
        elif f'.set_exclusive_zone({zone})' not in requests:
            raise ValueError(f'{label}: missing {role} exclusive zone {zone}')
        if '.ack_configure(' not in requests:
            raise ValueError(f'{label}: no configure acknowledgement for {role}')
    for role in expected:
        if role not in roles:
            raise ValueError(f'{label}: missing actual Wayland layer role: {role}')
    if re.search(r'protocol error|error 71|Failed to initialize layer-shell integration', log, re.I):
        raise ValueError(f'{label}: compositor protocol failure')
    return roles


def main():
    output = Path(sys.argv[1])
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


if __name__ == "__main__":
    main()
