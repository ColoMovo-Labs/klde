#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
entry=packaging/session/org.owode.GnomeSettings.desktop
# desktop-file-utils has a fixed table of desktop names and rejects owoDE.
# Check the custom session restriction explicitly, then validate all remaining
# fields. Do not drop the restriction from the installed desktop entry.
python3 - "$entry" packaging/session/owode.desktop <<'PY'
import configparser
import shlex
import sys

def read(path):
    parser = configparser.ConfigParser(interpolation=None)
    if not parser.read(path):
        raise ValueError(f"Missing desktop entry: {path}")
    return parser['Desktop Entry']

entry, session = map(read, sys.argv[1:])
assert entry['OnlyShowIn'] == session['DesktopNames'] == 'owoDE;'
assert 'NotShowIn' not in entry
assert entry.get('DBusActivatable', 'false') == 'false'
assert entry['TryExec'] == 'gnome-control-center'
assert shlex.split(entry['Exec']) == ['env', 'XDG_CURRENT_DESKTOP=GNOME', 'gnome-control-center']
PY
scratch=$(mktemp --suffix=.desktop)
trap 'rm -f "$scratch"' EXIT
sed '/^OnlyShowIn=/d' "$entry" > "$scratch"
desktop-file-validate "$scratch"
