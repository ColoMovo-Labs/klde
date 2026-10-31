// SPDX-License-Identifier: GPL-3.0-or-later
#include "UPowerBatterySource.h"
#include "mock/SystemStateModel.h"
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <algorithm>
#include <cmath>
#include <utility>

namespace {
const QString &service() {
    static const QString value = QStringLiteral("org.freedesktop.UPower");
    return value;
}
const QString &displayDevice() {
    static const QString value = QStringLiteral("/org/freedesktop/UPower/devices/DisplayDevice");
    return value;
}
const QString &deviceInterface() {
    static const QString value = QStringLiteral("org.freedesktop.UPower.Device");
    return value;
}
const QString &propertiesInterface() {
    static const QString value = QStringLiteral("org.freedesktop.DBus.Properties");
    return value;
}
} // namespace

namespace klde {
UPowerBatterySource::UPowerBatterySource(SystemStateModel *state, QDBusConnection bus,
                                         QObject *parent)
    : QObject(parent), m_state(state), m_bus(std::move(bus)),
      m_watcher(service(), m_bus, QDBusServiceWatcher::WatchForRegistration) {
    connect(&m_watcher, &QDBusServiceWatcher::serviceRegistered, this,
            &UPowerBatterySource::refresh);
}

void UPowerBatterySource::start() {
    // Until UPower answers, a battery is reported as absent rather than invented.
    m_state->publishLive(QStringLiteral("capabilities.battery"), false);
    m_bus.connect(service(), displayDevice(), propertiesInterface(),
                  QStringLiteral("PropertiesChanged"), this,
                  SLOT(propertiesChanged(QString, QVariantMap, QStringList)));
    refresh();
}

void UPowerBatterySource::refresh() {
    auto message = QDBusMessage::createMethodCall(service(), displayDevice(), propertiesInterface(),
                                                  QStringLiteral("GetAll"));
    message << deviceInterface();
    auto *call = new QDBusPendingCallWatcher(m_bus.asyncCall(message), this);
    connect(call, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *self) {
        const QDBusPendingReply<QVariantMap> reply = *self;
        self->deleteLater();
        if (reply.isError()) {
            m_properties.clear();
            m_state->publishLive(QStringLiteral("capabilities.battery"), false);
            return;
        }
        m_properties = reply.value();
        apply(m_properties);
    });
}

void UPowerBatterySource::propertiesChanged(const QString &interface, const QVariantMap &changed,
                                            const QStringList &invalidated) {
    if (interface != deviceInterface())
        return;
    if (!invalidated.isEmpty()) {
        refresh();
        return;
    }
    for (auto it = changed.cbegin(); it != changed.cend(); ++it)
        m_properties.insert(it.key(), it.value());
    apply(m_properties);
}

QVariantMap UPowerBatterySource::project(const QVariantMap &properties) {
    const bool present = properties.value(QStringLiteral("IsPresent")).toBool() &&
                         properties.value(QStringLiteral("Type")).toUInt() == 2;
    if (!present)
        return {{QStringLiteral("available"), false}};
    const double percentage = properties.value(QStringLiteral("Percentage")).toDouble();
    const uint state = properties.value(QStringLiteral("State")).toUInt();
    return {{QStringLiteral("available"), std::isfinite(percentage)},
            {QStringLiteral("percent"),
             std::clamp(static_cast<int>(std::lround(std::isfinite(percentage) ? percentage : 0)),
                        0, 100)},
            {QStringLiteral("charging"), state == 1 || state == 4 || state == 5}};
}

void UPowerBatterySource::apply(const QVariantMap &properties) {
    const auto battery = project(properties);
    const bool available = battery.value(QStringLiteral("available")).toBool();
    if (available) {
        m_state->publishLive(QStringLiteral("battery.percent"),
                             battery.value(QStringLiteral("percent")).toInt());
        m_state->publishLive(QStringLiteral("battery.charging"),
                             battery.value(QStringLiteral("charging")).toBool());
    }
    m_state->publishLive(QStringLiteral("capabilities.battery"), available);
}
} // namespace klde
