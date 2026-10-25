#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
qml="${QML_RUNTIME:-}"
if [[ -z "$qml" ]]; then
    for candidate in /usr/lib64/qt6/bin/qml /usr/lib/qt6/bin/qml; do
        if [[ -x "$candidate" ]]; then qml="$candidate"; break; fi
    done
fi
[[ -x "$qml" ]] || { echo 'Install the Qt 6 QML runtime, or set QML_RUNTIME to its path.' >&2; exit 2; }
export QT_QUICK_CONTROLS_STYLE=Basic
exec "$qml" -I "$root/design" "$root/design/Preview.qml" -- "$@"
