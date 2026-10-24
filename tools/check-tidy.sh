#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
build_dir="${BUILD_DIR:-build/ci}"
if [[ ! -f "$build_dir/compile_commands.json" ]]; then
    echo "clang-tidy: compile database not found at $build_dir/compile_commands.json" >&2
    exit 2
fi
while IFS= read -r -d '' source; do
    clang-tidy -p "$build_dir" "$source"
done < <(git ls-files -z -- 'src/*.cpp' 'src/**/*.cpp')
