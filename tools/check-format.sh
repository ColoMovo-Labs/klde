#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

git ls-files -z -- '*.cpp' '*.h' | xargs -0 -r clang-format --dry-run --Werror
if [[ "${CHECK_CPP_ONLY:-0}" == 1 ]]; then
    exit 0
fi
qt_tools="$(qtpaths6 --query QT_HOST_BINS)"
qmlformat="${QMLFORMAT:-$qt_tools/qmlformat}"
scratch="$(mktemp --suffix=.qml)"
trap 'rm -f "$scratch"' EXIT
while IFS= read -r -d '' source; do
    "$qmlformat" "$source" > "$scratch"
    diff -u "$source" "$scratch"
done < <(git ls-files -z -- '*.qml')
