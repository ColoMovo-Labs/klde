#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
output="$(realpath -m "${1:-artifacts/designer}")"
mkdir -p "$output"
puppet="${QMLPUPPET:-}"
if [[ -z "$puppet" ]]; then
    for candidate in /usr/libexec/qtcreator/qmlpuppet-* /usr/lib/qtcreator/qmlpuppet-*; do
        if [[ -x "$candidate" ]]; then puppet="$candidate"; break; fi
    done
fi
[[ -x "$puppet" ]] || { echo 'QML Designer puppet is not installed' >&2; exit 2; }
printf '%s\n' "$puppet" > "$output/renderer.txt"
for source in "$root"/design/scenes/*.ui.qml; do
    name="$(basename "$source" .ui.qml)"
    xvfb-run -a -s '-screen 0 1920x1080x24' \
        env -u QT_QUICK_BACKEND QT_QPA_PLATFORM=xcb LIBGL_ALWAYS_SOFTWARE=1 \
        QML_IMPORT_PATH="$root/design" QT_QUICK_CONTROLS_STYLE=Basic \
        "$puppet" --qml-renderer -i "$root/design" --maxW 1920 --maxH 1080 \
        -o "$output/$name.png" "$source" > "$output/$name.log" 2>&1
    test -s "$output/$name.png"
    if grep -E 'Critical:|ReferenceError:|TypeError:|Cannot assign|Cannot open:' "$output/$name.log"; then exit 1; fi
done
