#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

test "${CIRCLECI:-}" = true

build_dir="$(realpath "${1:?Pass the cloud-built CMake directory}")"
package_dir="$PWD/artifacts/packages"
mkdir -p "$package_dir"
revision="$(git rev-parse HEAD)"
short_revision="${revision:0:12}"
source_epoch="$(git show -s --format=%ct HEAD)"
export SOURCE_DATE_EPOCH="$source_epoch"

# Archive the same committed sources from which CircleCI built this binary.
git archive --format=tar --prefix=klde-source/ HEAD | gzip -n > "$package_dir/klde-source-$short_revision.tar.gz"
cpack --config "$build_dir/CPackConfig.cmake" -G DEB -B "$package_dir" \
    -D "CPACK_DEBIAN_PACKAGE_RELEASE=0.git$source_epoch.$short_revision"
rm -rf "$package_dir/_CPack_Packages"
mapfile -t packages < <(find "$package_dir" -maxdepth 1 -name '*.deb' -type f)
test "${#packages[@]}" -eq 1
package="${packages[0]}"
dpkg-deb --info "$package" > "$package_dir/control.txt"
dpkg-deb --contents "$package" > "$package_dir/contents.txt"
printf '%s\n' "$revision" > "$package_dir/source-commit.txt"
(cd "$package_dir" && sha256sum "$(basename "$package")" "klde-source-$short_revision.tar.gz" > SHA256SUMS)
