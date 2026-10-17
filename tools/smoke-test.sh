#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

shell_binary="$(realpath "${1:?Pass the cloud-built klde-shell path}")"
mkdir -p artifacts/smoke
smoke_dir="$(realpath artifacts/smoke)"
runtime_dir="$(mktemp -d)"
chmod 700 "$runtime_dir"
weston_pid=""
cleanup() {
    if [ -n "$weston_pid" ]; then
        kill "$weston_pid" 2>/dev/null || true
        wait "$weston_pid" 2>/dev/null || true
    fi
    rm -rf "$runtime_dir"
}
trap cleanup EXIT
export XDG_RUNTIME_DIR="$runtime_dir"

env QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    "$shell_binary" --smoke-test --capture "$smoke_dir/offscreen.png" \
    > "$smoke_dir/offscreen.log" 2>&1

weston --backend=headless --renderer=pixman --socket=wayland-klde \
    --idle-time=0 --width=1280 --height=800 --log="$smoke_dir/weston.log" &
weston_pid=$!
for attempt in {1..100}; do
    if [ -S "$runtime_dir/wayland-klde" ]; then
        break
    fi
    if ! kill -0 "$weston_pid" 2>/dev/null; then
        cat "$smoke_dir/weston.log"
        exit 1
    fi
    sleep 0.1
done
test -S "$runtime_dir/wayland-klde"
env QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=wayland-klde QT_QUICK_BACKEND=software \
    "$shell_binary" --smoke-test --capture "$smoke_dir/wayland.png" \
    > "$smoke_dir/wayland.log" 2>&1

# llvmpipe checks the OpenGL path. It is not an Intel GPU benchmark.
xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 glxinfo -B > "$smoke_dir/glxinfo.txt"
xvfb-run -a env -u QT_QUICK_BACKEND QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl \
    LIBGL_ALWAYS_SOFTWARE=1 QSG_INFO=1 \
    "$shell_binary" --smoke-test --audit-idle --capture "$smoke_dir/llvmpipe.png" \
    > "$smoke_dir/llvmpipe.log" 2>&1

test -s "$smoke_dir/offscreen.png"
test -s "$smoke_dir/wayland.png"
test -s "$smoke_dir/llvmpipe.png"

smoke_status=0
for view in temporal wallpaper-effects lock-preview waydroid quick-settings launcher blur power-scenes weather language input notifications ribbon ribbon-settings input-candidate mock-lab app-suite; do
    if ! xvfb-run -a env -u QT_QUICK_BACKEND QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl \
        LIBGL_ALWAYS_SOFTWARE=1 QSG_INFO=1 \
        "$shell_binary" --smoke-test --view "$view" --audit-idle \
        --capture "$smoke_dir/$view.png" > "$smoke_dir/$view.log" 2>&1; then
        cat "$smoke_dir/$view.log"
        smoke_status=1
    fi
done
if ! xvfb-run -a env -u QT_QUICK_BACKEND QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl \
    LIBGL_ALWAYS_SOFTWARE=1 "$shell_binary" --smoke-test --audit-idle --dark --view quick-settings \
    --capture "$smoke_dir/dark.png" > "$smoke_dir/dark.log" 2>&1; then
    cat "$smoke_dir/dark.log"
    smoke_status=1
fi
for variant in zh_CN zh_CN-cute en-cute; do
    locale="${variant%%-*}"
    voice=standard
    if [[ "$variant" == *-cute ]]; then voice=cute; fi
    if ! xvfb-run -a env -u QT_QUICK_BACKEND QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl \
        LIBGL_ALWAYS_SOFTWARE=1 "$shell_binary" --smoke-test --audit-idle \
        --view quick-settings --locale "$locale" --voice "$voice" \
        --capture "$smoke_dir/$variant.png" > "$smoke_dir/$variant.log" 2>&1; then
        cat "$smoke_dir/$variant.log"
        smoke_status=1
    fi
done
xvfb-run -a env -u QT_QUICK_BACKEND QT_QPA_PLATFORM=xcb QSG_RHI_BACKEND=opengl \
    LIBGL_ALWAYS_SOFTWARE=1 "$shell_binary" --smoke-test --locale zh_CN --voice cute --view language \
    --capture "$smoke_dir/language-zh_CN.png" > "$smoke_dir/language-zh_CN.log" 2>&1
# Exercise the same focus/typing/token suite through each real QPA path.
qml_test_binary="$(dirname "$shell_binary")/klde-qml-tests"
env QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=wayland-klde QT_QUICK_BACKEND=software \
    QT_QUICK_CONTROLS_STYLE=Basic "$qml_test_binary" \
    > "$smoke_dir/wayland-interaction.log" 2>&1
xvfb-run -a env QT_QPA_PLATFORM=xcb QT_QUICK_BACKEND=software QT_QUICK_CONTROLS_STYLE=Basic \
    "$qml_test_binary" > "$smoke_dir/xcb-interaction.log" 2>&1

exit "$smoke_status"
