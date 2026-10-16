#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
while IFS= read -r -d '' source; do
    clang-tidy -p build/ci "$source"
done < <(git ls-files -z -- 'src/*.cpp' 'src/**/*.cpp')
