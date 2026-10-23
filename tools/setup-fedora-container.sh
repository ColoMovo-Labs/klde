#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
image=${LOMODE_FEDORA_IMAGE:-localhost/lomode-fedora:44}
runtime=${LOMODE_CONTAINER_RUNTIME:-podman}

if ! command -v "$runtime" >/dev/null 2>&1; then
    echo "owoDE Fedora setup: $runtime is required." >&2
    echo "Install Podman or use Fedora Toolbx, then rerun this script." >&2
    exit 2
fi

echo "Building $image from containers/lomode-fedora.Containerfile"
"$runtime" build --tag "$image" --file "$root_dir/containers/lomode-fedora.Containerfile" "$root_dir"
echo
echo "Build environment ready. Enter it without automatic host socket or GPU mounts:"
echo "  $runtime run --rm -it --userns=keep-id -v '$root_dir:/workspace:Z' -w /workspace '$image'"
echo
echo "Runtime validation remains a separate step. Install/use KWin on Fedora and"
echo "run bash tools/probe-real-session.sh and bash tools/run-lomode-session.sh there."
