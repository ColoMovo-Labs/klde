// SPDX-License-Identifier: GPL-3.0-or-later
#include "LiveSystemBackend.h"
#include "mock/SystemStateModel.h"
#include <algorithm>

namespace klde {
LiveSystemBackend::LiveSystemBackend(SystemStateModel *state, SystemBackend *preview,
                                     QObject *parent)
    : SystemBackend(parent), m_state(state), m_preview(preview) {
    connect(state, &SystemStateModel::changed, this, &SystemBackend::stateChanged);
}

int LiveSystemBackend::volume() const {
    return m_state->value(QStringLiteral("audio.volume")).toInt();
}

int LiveSystemBackend::brightness() const {
    return m_state->value(QStringLiteral("brightness")).toInt();
}

bool LiveSystemBackend::wifi() const {
    return m_state->value(QStringLiteral("network.enabled")).toBool();
}

bool LiveSystemBackend::bluetooth() const {
    return m_state->value(QStringLiteral("bluetooth.enabled")).toBool();
}

bool LiveSystemBackend::nightMode() const {
    return m_state->value(QStringLiteral("nightMode")).toBool();
}

QString LiveSystemBackend::powerProfile() const {
    return profileName(m_state->value(QStringLiteral("powerProfile")).toString());
}

QString LiveSystemBackend::profileId(const QString &displayName) {
    if (displayName == QLatin1String("Performance"))
        return QStringLiteral("performance");
    if (displayName == QLatin1String("Power saver"))
        return QStringLiteral("power-saver");
    if (displayName == QLatin1String("Balanced"))
        return QStringLiteral("balanced");
    return {};
}

QString LiveSystemBackend::profileName(const QString &id) {
    if (id == QLatin1String("performance"))
        return QStringLiteral("Performance");
    if (id == QLatin1String("power-saver"))
        return QStringLiteral("Power saver");
    return QStringLiteral("Balanced");
}

void LiveSystemBackend::setVolume(int value) {
    request(QStringLiteral("audio.volume"), std::clamp(value, 0, 100));
}

void LiveSystemBackend::setBrightness(int value) {
    request(QStringLiteral("brightness"), std::clamp(value, 0, 100));
}

void LiveSystemBackend::setWifi(bool value) { request(QStringLiteral("network.enabled"), value); }

void LiveSystemBackend::setBluetooth(bool value) {
    request(QStringLiteral("bluetooth.enabled"), value);
}

void LiveSystemBackend::setNightMode(bool value) { request(QStringLiteral("nightMode"), value); }

void LiveSystemBackend::setPowerProfile(const QString &profile) {
    const auto id = profileId(profile);
    if (id.isEmpty()) {
        emit requestRejected(tr("Unknown power profile"));
        return;
    }
    // A machine without a profile daemon still applies the scene's visuals.
    if (m_state->value(QStringLiteral("capabilities.powerProfiles")).toBool() &&
        m_state->value(QStringLiteral("powerProfile")).toString() != id)
        request(QStringLiteral("powerProfile"), id);
}

void LiveSystemBackend::request(const QString &path, const QVariant &value) {
    // Confirmation arrives later through the service; a refused request is
    // reported instead of pretending the control moved.
    if (!m_state->requestValue(path, value))
        emit requestRejected(tr("That setting is unavailable right now"));
}
} // namespace klde
