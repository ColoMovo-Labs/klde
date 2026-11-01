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
    # These upstream files stay byte-identical; their hashes and license are
    # checked by lockscreen-source-contract rather than our QML formatter.
    case "$source" in
        packaging/lockscreen/org.owode.shell/contents/lockscreen/Greeter.qml|packaging/lockscreen/org.owode.shell/contents/lockscreen/PasswordSync.qml) continue ;;
    esac
    "$qmlformat" "$source" > "$scratch"
    diff -u "$source" "$scratch"
done < <(git ls-files -z -- '*.qml')
