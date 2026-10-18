# SPDX-License-Identifier: GPL-3.0-or-later
FROM fedora:44

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    QT_QPA_PLATFORM=wayland

RUN dnf install -y --setopt=install_weak_deps=False \
        @development-tools \
        ccache cmake ninja-build git file findutils \
        qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtwayland-devel \
        qt6-qtsvg qt6-qttools-devel layer-shell-qt layer-shell-qt-devel \
        kwin wayland-devel wayland-protocols-devel \
        mesa-dri-drivers mesa-libEGL mesa-libGL \
        dbus-daemon dbus-tools xorg-x11-server-Xwayland \
        desktop-file-utils \
    && dnf clean all \
    && mkdir -p /workspace

WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]
