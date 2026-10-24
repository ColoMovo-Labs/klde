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
        if ! env XDG_RUNTIME_DIR="$runtime_dir" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
            "$build_dir/bin/owode-calculator" --smoke-test --locale "$locale" "${flags[@]}" \
            --capture "$PWD/$out_dir/calculator-$locale-$mode.png" \
            > "$out_dir/calculator-$locale-$mode.log" 2>&1; then
            cat "$out_dir/calculator-$locale-$mode.log"
            exit 1
        fi
    done
done
revision="$(git rev-parse HEAD)"
release="1.$(git show -s --format=%ct HEAD).git${revision:0:12}"
if command -v dnf >/dev/null; then
    cpack --config "$build_dir/CPackConfig.cmake" -G RPM -B "$out_dir" \
        -D "CPACK_RPM_PACKAGE_RELEASE=$release"
    # Minimal Fedora cloud images default to nodocs; this job verifies the
    # corresponding source too, so retain this package's documentation.
    dnf install -y --setopt=tsflags= "$PWD/$out_dir/"*.rpm
else
    cpack --config "$build_dir/CPackConfig.cmake" -G DEB -B "$out_dir" \
        -D "CPACK_DEBIAN_PACKAGE_RELEASE=$release"
    mkdir -p /etc/dpkg/dpkg.cfg.d
    printf '%s\n' 'path-include=/usr/share/doc/owode-calculator' 'path-include=/usr/share/doc/owode-calculator/*' > /etc/dpkg/dpkg.cfg.d/zz-owode-calculator-docs
    apt-get install -y "$PWD/$out_dir/"*.deb
fi
env XDG_RUNTIME_DIR="$runtime_dir" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    /usr/bin/owode-calculator --smoke-test --capture "$PWD/$out_dir/installed.png"
desktop-file-validate apps/calculator/org.owode.Calculator.desktop
source_root=/usr/share/doc/owode-calculator/source
python3 "$source_root/tools/fetch-lingmo-calculator.py" "$runtime_dir/offline-upstream" \
    --archive "$source_root/lingmo-calculator-source.tar.gz"
cmake -S "$source_root/apps/calculator" -B build/calculator-source-check -G Ninja \
    -DOWODE_LINGMO_CALCULATOR_SOURCE_DIR="$runtime_dir/offline-upstream"
cp "$source_dir/../lingmo-calculator-source.tar.gz" "$out_dir/"
git archive --format=tar.gz --prefix=owode/ HEAD > "$out_dir/owode-port-source.tar.gz"
printf '%s\n' "$revision" > "$out_dir/source-commit.txt"
rm -rf "$out_dir/_CPack_Packages"
(cd "$out_dir" && find . -maxdepth 1 -type f \( -name '*.rpm' -o -name '*.deb' -o -name '*.tar.gz' \) -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
