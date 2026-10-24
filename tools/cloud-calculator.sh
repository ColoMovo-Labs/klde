#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
# Cloud job only. The optional app never changes the shell's dependency graph.
build_dir=build/calculator
source_dir=build/lingmo-calculator
out_dir=artifacts/calculator
python3 tools/fetch-lingmo-calculator.py "$source_dir"
cmake -S apps/calculator -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DOWODE_LINGMO_CALCULATOR_SOURCE_DIR="$PWD/$source_dir"
cmake --build "$build_dir" --parallel 2
mkdir -p "$out_dir"
ctest --test-dir "$build_dir" --output-on-failure --output-junit "$PWD/$out_dir/tests.xml"
cmake --build "$build_dir" --target all_qmllint --parallel 2
runtime_dir="$(mktemp -d)"
chmod 700 "$runtime_dir"
trap 'rm -rf "$runtime_dir"' EXIT
for locale in en zh_CN; do
    for mode in light dark; do
        flags=()
        [[ "$mode" == dark ]] && flags+=(--dark)
        env XDG_RUNTIME_DIR="$runtime_dir" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
            "$build_dir/bin/owode-calculator" --smoke-test --locale "$locale" "${flags[@]}" \
            --capture "$PWD/$out_dir/calculator-$locale-$mode.png" \
            > "$out_dir/calculator-$locale-$mode.log" 2>&1
    done
done
revision="$(git rev-parse HEAD)"
release="1.$(git show -s --format=%ct HEAD).git${revision:0:12}"
if command -v dnf >/dev/null; then
    cpack --config "$build_dir/CPackConfig.cmake" -G RPM -B "$out_dir" \
        -D "CPACK_RPM_PACKAGE_RELEASE=$release"
    dnf install -y "$out_dir/"*.rpm
else
    cpack --config "$build_dir/CPackConfig.cmake" -G DEB -B "$out_dir" \
        -D "CPACK_DEBIAN_PACKAGE_RELEASE=$release"
    apt-get install -y "$out_dir/"*.deb
fi
env XDG_RUNTIME_DIR="$runtime_dir" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    /usr/bin/owode-calculator --smoke-test --capture "$PWD/$out_dir/installed.png"
desktop-file-validate apps/calculator/org.owode.Calculator.desktop
cp "$source_dir/../lingmo-calculator-source.tar.gz" "$out_dir/"
git archive --format=tar.gz --prefix=owode/ HEAD > "$out_dir/owode-port-source.tar.gz"
printf '%s\n' "$revision" > "$out_dir/source-commit.txt"
rm -rf "$out_dir/_CPack_Packages"
(cd "$out_dir" && sha256sum ./*.rpm ./*.deb ./*.tar.gz 2>/dev/null > SHA256SUMS) || \
    (cd "$out_dir" && find . -maxdepth 1 -type f \( -name '*.rpm' -o -name '*.deb' -o -name '*.tar.gz' \) -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
