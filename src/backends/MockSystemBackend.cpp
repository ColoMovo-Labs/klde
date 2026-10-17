// SPDX-License-Identifier: GPL-3.0-or-later
#include "MockSystemBackend.h"
#include <algorithm>

namespace klde {
void MockSystemBackend::applyPreviewState(const QVariantMap &snapshot) {
    m_volume = std::clamp(snapshot.value("audio").toMap().value("volume").toInt(), 0, 100);
    m_brightness = std::clamp(snapshot.value("brightness").toInt(), 0, 100);
    m_wifi = snapshot.value("network").toMap().value("enabled").toBool();
    m_bluetooth = snapshot.value("bluetooth").toMap().value("enabled").toBool();
    m_nightMode = snapshot.value("nightMode").toBool();
    emit stateChanged();
}
void MockSystemBackend::setVolume(int value) {
    value = std::clamp(value, 0, 100);
    if (m_volume != value) {
        m_volume = value;
        emit stateChanged();
        emit osdRequested(QStringLiteral("volume"), value);
    }
}
void MockSystemBackend::setBrightness(int value) {
    value = std::clamp(value, 0, 100);
    if (m_brightness != value) {
        m_brightness = value;
        emit stateChanged();
        emit osdRequested(QStringLiteral("brightness"), value);
    }
}
void MockSystemBackend::setWifi(bool value) {
    if (m_wifi != value) {
        m_wifi = value;
        emit stateChanged();
    }
}
void MockSystemBackend::setBluetooth(bool value) {
    if (m_bluetooth != value) {
        m_bluetooth = value;
        emit stateChanged();
    }
}
void MockSystemBackend::setNightMode(bool value) {
    if (m_nightMode != value) {
        m_nightMode = value;
        emit stateChanged();
    }
}
void MockSystemBackend::setPowerProfile(const QString &profile) {
    if (profile != "Balanced" && profile != "Power saver" && profile != "Performance") {
        emit requestRejected(tr("Unknown power profile"));
        return;
    }
    if (m_powerProfile != profile) {
        m_powerProfile = profile;
        emit stateChanged();
    }
}
bool MockSystemBackend::requestSessionAction(const QString &action) {
    if (action != "shutdown" && action != "logout" && action != "suspend") {
        emit requestRejected(tr("Unknown session action"));
        return false;
    }
    emit actionReported(tr("Preview: %1 requested. Your session is unchanged.").arg(action));
    return true;
}
} // namespace klde
