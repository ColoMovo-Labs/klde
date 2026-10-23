#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Package an already cloud-built Fedora install tree. This script does not
# compile; it is intentionally called after the Fedora CI build and tests.
set -euo pipefail

build_dir="$(realpath "${1:?Pass the cloud-built CMake directory}")"
out_dir="${2:-artifacts/fedora}"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"

test -f "$build_dir/cmake_install.cmake"
commit="${CIRCLE_SHA1:-$(git rev-parse HEAD)}"
short_commit="${commit:0:12}"
version="$(sed -n 's/^project(KLDE VERSION \([^ )]*\).*/\1/p' CMakeLists.txt | head -n 1)"
test -n "$version"

stage_dir="$(mktemp -d)"
trap 'rm -rf "$stage_dir"' EXIT
prefix="$stage_dir/owode"
archive="owode-shell-fedora44-${version}-git${short_commit}.tar.gz"

cmake --install "$build_dir" --prefix "$prefix"
mkdir -p "$prefix/share/doc/owode-shell-preview"
cat > "$prefix/share/doc/owode-shell-preview/README-Fedora.md" <<'EOF'
# owoDE Fedora cloud bundle

This is an experimental user-installable Fedora bundle produced by the Fedora
cloud build. It contains the standalone `klde-shell` preview and its desktop
resources. It does not replace the current desktop session or install a login
manager entry.

Extract the archive into `~/.local` and run `~/.local/bin/klde-shell`.
Install Fedora's Qt 6 runtime packages before launching it. Native KWin
surface mode additionally requires KWin and LayerShellQt.
EOF

(cd "$stage_dir" && tar -czf "$out_dir/$archive" owode)
cpack --config "$build_dir/CPackConfig.cmake" -G RPM -B "$out_dir"
rm -rf "$out_dir/_CPack_Packages"
mapfile -t rpms < <(find "$out_dir" -maxdepth 1 -name '*.rpm' -type f -print)
test "${#rpms[@]}" -eq 1
printf '%s\n' "$commit" > "$out_dir/${archive%.tar.gz}.source-commit.txt"
printf '%s\n' "$archive" > "$out_dir/${archive%.tar.gz}.manifest.txt"
(cd "$stage_dir" && find owode -type f -printf '%P\n' | sort) >> "$out_dir/${archive%.tar.gz}.manifest.txt"
(cd "$out_dir" && sha256sum "$archive" "$(basename "${rpms[0]}")" > SHA256SUMS)
