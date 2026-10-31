// SPDX-License-Identifier: GPL-3.0-or-later
#include "LiveSystemBackend.h"
#include "mock/SystemStateModel.h"

namespace klde {
LiveSystemBackend::LiveSystemBackend(SystemStateModel *state, SystemBackend *preview,
                                     QObject *parent)
    : SystemBackend(parent), m_state(state), m_preview(preview) {
    connect(state, &SystemStateModel::changed, this, &SystemBackend::stateChanged);
    connect(preview, &SystemBackend::stateChanged, this, &SystemBackend::stateChanged);
    connect(preview, &SystemBackend::osdRequested, this, &SystemBackend::osdRequested);
}

bool LiveSystemBackend::wifi() const {
    return m_state->value(QStringLiteral("network.enabled")).toBool();
}

bool LiveSystemBackend::bluetooth() const {
    return m_state->value(QStringLiteral("bluetooth.enabled")).toBool();
}

void LiveSystemBackend::setWifi(bool value) { request(QStringLiteral("network.enabled"), value); }

void LiveSystemBackend::setBluetooth(bool value) {
    request(QStringLiteral("bluetooth.enabled"), value);
}

void LiveSystemBackend::request(const QString &path, bool value) {
    // Confirmation arrives later through the service; a refused request is
    // reported instead of pretending the switch moved.
    if (!m_state->requestValue(path, value))
        emit requestRejected(tr("That setting is unavailable right now"));
}
} // namespace klde
