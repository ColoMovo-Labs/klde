// SPDX-License-Identifier: GPL-3.0-or-later
#include "SessionRuntimeBackend.h"

#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusReply>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <algorithm>

namespace klde {

namespace {
bool hasLayerShellQmlModule() {
    const QStringList candidates{
        QStringLiteral("/usr/lib64/qt6/qml/org/kde/layershell/qmldir"),
        QStringLiteral("/usr/lib/qt6/qml/org/kde/layershell/qmldir"),
        QStringLiteral("/usr/lib/qt6/qml/org/kde/layershell/liblayershellplugin.so")};
    return std::any_of(candidates.cbegin(), candidates.cend(),
                       [](const QString &path) { return QFileInfo::exists(path); });
}
} // namespace

SessionRuntimeBackend::SessionRuntimeBackend(QObject *parent) : QObject(parent) { refresh(); }

bool SessionRuntimeBackend::refresh() {
    const auto env = QProcessEnvironment::systemEnvironment();
    const bool wayland =
        env.value(QStringLiteral("XDG_SESSION_TYPE")) == QStringLiteral("wayland") ||
        !env.value(QStringLiteral("WAYLAND_DISPLAY")).isEmpty();
    bool kwinService = false;
    const auto bus = QDBusConnection::sessionBus();
    if (bus.isConnected()) {
        if (auto *interface = bus.interface()) {
            const QDBusReply<bool> reply =
                interface->isServiceRegistered(QStringLiteral("org.kde.KWin"));
            kwinService = reply.isValid() && reply.value();
        }
    }
    const bool kwinHint = kwinService || !env.value(QStringLiteral("KWIN_VERSION")).isEmpty() ||
                          env.value(QStringLiteral("KDE_SESSION_VERSION")) == QStringLiteral("6");
    const bool layerShell = hasLayerShellQmlModule();
    const QString display = env.value(QStringLiteral("WAYLAND_DISPLAY"));
    QString compositor = env.value(QStringLiteral("XDG_CURRENT_DESKTOP"));
    if (compositor.isEmpty() && kwinService)
        compositor = QStringLiteral("KWin");
    QString diagnostic;
    if (!wayland) {
        diagnostic =
            QStringLiteral("No Wayland session detected; the current shell is a preview window.");
    } else if (!kwinService) {
        diagnostic = QStringLiteral(
            "Wayland is available, but the org.kde.KWin session service is not registered.");
    } else if (!layerShell) {
        diagnostic = QStringLiteral(
            "KWin is visible, but LayerShellQt is unavailable; shell surfaces remain gated.");
    } else {
        diagnostic = QStringLiteral("Wayland, KWin and the LayerShellQt probe are available.");
    }
    const bool changedState = m_waylandSession != wayland || m_kwinService != kwinService ||
                              m_kwinDetected != kwinHint || m_layerShellAvailable != layerShell ||
                              m_waylandDisplay != display || m_compositor != compositor ||
                              m_diagnostic != diagnostic;
    m_waylandSession = wayland;
    m_kwinService = kwinService;
    m_kwinDetected = kwinHint;
    m_layerShellAvailable = layerShell;
    m_waylandDisplay = display;
    m_compositor = compositor;
    m_diagnostic = diagnostic;
    if (changedState)
        emit changed();
    return m_waylandSession && m_kwinService;
}

QVariantMap SessionRuntimeBackend::capabilities() const {
    return {{QStringLiteral("wayland"), m_waylandSession},
            {QStringLiteral("kwinService"), m_kwinService},
            {QStringLiteral("kwinDetected"), m_kwinDetected},
            {QStringLiteral("layerShellQt"), m_layerShellAvailable},
            {QStringLiteral("realSessionReady"),
             m_waylandSession && m_kwinService && m_layerShellAvailable},
            {QStringLiteral("mock"), false},
            {QStringLiteral("diagnostic"), m_diagnostic}};
}

} // namespace klde
