// SPDX-License-Identifier: GPL-3.0-or-later
#include "DisplayServerBackend.h"
#include <QGuiApplication>

namespace klde {
QString DisplayServerBackend::platform() const { return QGuiApplication::platformName(); }
QString DisplayServerBackend::protocol() const {
    const auto name = platform();
    if (name.startsWith("wayland"))
        return QStringLiteral("wayland");
    return name == "xcb" ? QStringLiteral("x11") : QStringLiteral("headless-or-other");
}
QVariantMap DisplayServerBackend::capabilities() const {
    return {{"ordinaryWindow", true}, {"sessionHost", false},        {"globalShortcuts", false},
            {"nativeBlur", false},    {"otherWindowControl", false}, {"screenCapture", false}};
}
} // namespace klde
