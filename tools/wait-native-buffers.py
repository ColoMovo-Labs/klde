#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Wait for real CLI buffers and compositor mapping, not only configured roles."""
import argparse
import json
from pathlib import Path
import re
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('log', type=Path)
parser.add_argument('output', type=Path)
parser.add_argument('--timeout', type=float, default=30)
args = parser.parse_args()
if not 0 <= args.timeout <= 120:
    parser.error('timeout must be between 0 and 120 seconds')
expected = {
    'wallpaper': (0, 15, 'desktop'),
    'ribbon': (2, 13, 'dock'),
    'dock': (2, 14, 'dock'),
    'popup': (3, 15, 'on-screen-display'),
}
created = re.compile(
    r'get_layer_surface\(new id (zwlr_layer_surface_v1[@#]\d+), '
    r'(wl_surface[@#]\d+), .*?, (\d+), "(desktop|dock|on-screen-display)"\)')
start = time.monotonic()
args.output.unlink(missing_ok=True)
while True:
    lines = args.log.read_text(errors='replace').splitlines() if args.log.exists() else []
    ready = {}
    for index, line in enumerate(lines):
        match = created.search(line)
        if not match:
            continue
        layer, surface, number, namespace = match.groups()
        tail = lines[index:]
        layer_requests = '\n'.join(row for row in tail if layer + '.' in row)
        roles = [role for role, (value, anchor, scope) in expected.items()
                 if int(number) == value and namespace == scope
                 and f'.set_anchor({anchor})' in layer_requests]
        if len(roles) != 1:
            continue
        surface_requests = [row for row in tail if surface + '.' in row]
        attach = re.compile(re.escape(surface) + r'\.attach\(wl_buffer[@#]\d+,')
        committed = any(
            attach.search(row) and any(surface + '.commit()' in later
                                      for later in surface_requests[position + 1:])
            for position, row in enumerate(surface_requests))
        mapped = any(surface + '.enter(' in row for row in surface_requests)
        if committed and mapped:
            ready[roles[0]] = {'layerSurface': layer, 'surface': surface,
                              'bufferCommitted': True, 'compositorMapped': True}
    if set(ready) == set(expected):
        args.output.write_text(json.dumps({
            'readyRoles': ready, 'observedAfterSeconds': round(time.monotonic() - start, 3),
            'scope': 'First buffers and output membership; inspect the actual PNG separately',
            'hardwarePerformanceBenchmark': False,
        }, indent=2) + '\n')
        print('All four native CLI surfaces committed buffers and entered the output')
        break
    if time.monotonic() - start >= args.timeout:
        raise SystemExit('Native CLI buffers/mapping not ready: ' + ', '.join(sorted(set(expected) - set(ready))))
    time.sleep(0.1)
