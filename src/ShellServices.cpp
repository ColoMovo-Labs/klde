// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"

namespace klde {
ShellServices::ShellServices(QObject *parent) : QObject(parent), m_search(&m_applications) {
    m_noticeTimer.setSingleShot(true);
    m_noticeTimer.setInterval(2400);
    connect(&m_noticeTimer, &QTimer::timeout, this, [this] {
        m_message.clear();
        m_osdValue = -1;
        emit messageChanged();
    });
    connect(&m_system, &SystemBackend::actionReported, this, &ShellServices::showNotice);
    connect(&m_system, &SystemBackend::requestRejected, this, &ShellServices::showNotice);
    connect(&m_windowManager, &WindowManagerBackend::requestRejected, this,
            &ShellServices::showNotice);
    connect(&m_system, &SystemBackend::osdRequested, this, [this](const QString &kind, int value) {
        showNotice(kind == "volume" ? tr("Volume") : tr("Brightness"));
        m_osdValue = value;
        emit messageChanged();
    });
}
QVariantMap ShellServices::weather() const {
    return {{"location", "Snowline"},
            {"temperature", 18},
            {"condition", "Clouds & sunshine"},
            {"high", 21},
            {"low", 12},
            {"sourceLabel", "Mock weather"}};
}
bool ShellServices::launch(const QString &appId) {
    if (!m_applications.activate(appId)) {
        showNotice(tr("That application is unavailable"));
        return false;
    }
    showNotice(tr("Preview: %1 is active").arg(m_applications.nameFor(appId)));
    return true;
}
void ShellServices::showNotice(const QString &message) {
    m_message = message;
    m_osdValue = -1;
    m_noticeTimer.start();
    emit messageChanged();
}
} // namespace klde
