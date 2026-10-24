#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Run only in a cloud build. llvmpipe exercises the real Qt shader path; it is
# correctness/visual evidence, never a representative hardware GPU benchmark.
set -euo pipefail

shell_binary="$(realpath "${1:?Pass the cloud-built shell}")"
out_dir="${2:-artifacts/fusion}"
mkdir -p "$out_dir"
out_dir="$(realpath "$out_dir")"
runtime_dir="$(mktemp -d)"
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT

xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 glxinfo -B > "$out_dir/fusion-renderer.txt"
capture() {
    local name="$1"
    shift
    if ! xvfb-run -a -s '-screen 0 1920x1080x24' \
        env -u QT_QUICK_BACKEND QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl \
        LIBGL_ALWAYS_SOFTWARE=1 QSG_INFO=1 XDG_RUNTIME_DIR="$runtime_dir" \
        "$shell_binary" --smoke-test --audit-idle --size 1920x1080 --locale zh_CN \
        --capture "$out_dir/$name.png" "$@" > "$out_dir/$name.log" 2>&1; then
        cat "$out_dir/$name.log"
        return 1
    fi
    test -s "$out_dir/$name.png"
}

capture fusion-desktop-light --view desktop
capture fusion-quick-settings-light --view quick-settings
capture fusion-launcher-light --view launcher
capture fusion-temporal-light --view temporal
capture fusion-desktop-dark --view desktop --dark --wallpaper kemono
capture fusion-quick-settings-dark --view quick-settings --dark --wallpaper kemono
capture fusion-study-light --view material-study
capture fusion-study-dark --view material-study --dark --wallpaper kemono

git rev-parse HEAD > "$out_dir/fusion-source-commit.txt"
python3 - "$out_dir" <<'PY'
import json
from pathlib import Path
import struct
import sys

output = Path(sys.argv[1])
records = []
for path in sorted(output.glob('*.png')):
    width, height = struct.unpack('>II', path.read_bytes()[16:24])
    if (width, height) != (1920, 1080):
        raise SystemExit(f'Unexpected capture dimensions: {path.name}: {width}x{height}')
    records.append({'image': path.name, 'width': width, 'height': height,
                    'log': path.with_suffix('.log').name})
(output / 'fusion-manifest.json').write_text(json.dumps({
    'revision': (output / 'fusion-source-commit.txt').read_text().strip(),
    'renderer': 'Qt Quick OpenGL via Mesa llvmpipe in Xvfb',
    'mockSystemServices': True,
    'hardwarePerformanceBenchmark': False,
    'captures': records,
}, indent=2) + '\n')
PY
