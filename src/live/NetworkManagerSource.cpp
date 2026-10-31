// SPDX-License-Identifier: GPL-3.0-or-later
#include "NetworkManagerSource.h"
#include "mock/SystemStateModel.h"
#include <NetworkManagerQt/AccessPoint>
#include <NetworkManagerQt/ActiveConnection>
#include <NetworkManagerQt/Manager>
#include <NetworkManagerQt/WirelessDevice>
#include <algorithm>

namespace klde {
NetworkManagerSource::NetworkManagerSource(SystemStateModel *state, QObject *parent)
    : QObject(parent), m_state(state) {
    m_refresh.setSingleShot(true);
    m_refresh.setInterval(0);
    connect(&m_refresh, &QTimer::timeout, this, &NetworkManagerSource::refresh);
}

void NetworkManagerSource::start() {
    auto *notifier = NetworkManager::notifier();
    connect(notifier, &NetworkManager::Notifier::wirelessEnabledChanged, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::networkingEnabledChanged, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::statusChanged, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::connectivityChanged, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::primaryConnectionChanged, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::activeConnectionsChanged, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::deviceAdded, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::deviceRemoved, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::serviceAppeared, this,
            &NetworkManagerSource::schedule);
    connect(notifier, &NetworkManager::Notifier::serviceDisappeared, this,
            &NetworkManagerSource::schedule);
    m_state->setLiveWriter(QStringLiteral("network.enabled"),
                           [this](const QVariant &value) { return setEnabled(value.toBool()); });
    refresh();
}

QString NetworkManagerSource::displayName(const QString &raw) {
    QString result;
    for (const QChar c : raw) {
        if (c.isPrint())
            result.append(c);
        if (result.size() >= 64)
            break;
    }
    return result.trimmed();
}

bool NetworkManagerSource::setEnabled(bool enabled) {
    if (NetworkManager::status() == NetworkManager::Unknown)
        return false;
    // The switch is the Wi-Fi radio; a machine without Wi-Fi toggles networking.
    if (m_hasWifi)
        NetworkManager::setWirelessEnabled(enabled);
    else
        NetworkManager::setNetworkingEnabled(enabled);
    return true;
}

void NetworkManagerSource::refresh() {
    const auto status = NetworkManager::status();
    m_hasWifi = false;
    NetworkManager::WirelessDevice::Ptr wifi;
    for (const auto &device : NetworkManager::networkInterfaces()) {
        if (device->type() != NetworkManager::Device::Wifi)
            continue;
        m_hasWifi = true;
        const auto wireless = device.objectCast<NetworkManager::WirelessDevice>();
        if (!wireless)
            continue;
        // Roaming changes the access point without a new primary connection.
        connect(wireless.data(), &NetworkManager::WirelessDevice::activeAccessPointChanged, this,
                &NetworkManagerSource::schedule, Qt::UniqueConnection);
        if (!wifi)
            wifi = wireless;
    }
    const bool running = status != NetworkManager::Unknown;
    const bool enabled = running && (m_hasWifi ? NetworkManager::isWirelessEnabled()
                                               : NetworkManager::isNetworkingEnabled());
    const bool connected = status == NetworkManager::Connected ||
                           status == NetworkManager::ConnectedSiteOnly ||
                           status == NetworkManager::ConnectedLinkLocal;
    const auto connectivity = NetworkManager::connectivity();
    const bool internet = connectivity == NetworkManager::Full ||
                          (connectivity == NetworkManager::UnknownConnectivity &&
                           status == NetworkManager::Connected);

    QString name;
    int strength = 0;
    QString accessPoint;
    if (const auto primary = NetworkManager::primaryConnection(); primary && connected) {
        if (primary->type() == NetworkManager::ConnectionSettings::Wireless) {
            // The primary connection's specific object is its access point;
            // ActiveAccessPoint on the device is the fallback.
            NetworkManager::AccessPoint::Ptr ap;
            for (const auto &uni : primary->devices()) {
                const auto device = NetworkManager::findNetworkInterface(uni)
                                        .objectCast<NetworkManager::WirelessDevice>();
                if (!device)
                    continue;
                ap = device->findAccessPoint(primary->specificObject());
                if (!ap)
                    ap = device->activeAccessPoint();
                if (ap) {
                    wifi = device;
                    break;
                }
            }
            name = displayName(ap ? ap->ssid() : primary->id());
            if (ap) {
                strength = std::clamp(ap->signalStrength(), 0, 100);
                accessPoint = ap->uni();
            }
        } else {
            name = displayName(primary->id());
            strength = 100;
        }
    }
    if (accessPoint != m_accessPoint) {
        disconnect(m_strength);
        m_accessPoint = accessPoint;
        if (const auto ap = wifi ? wifi->findAccessPoint(accessPoint) : nullptr)
            m_strength = connect(ap.data(), &NetworkManager::AccessPoint::signalStrengthChanged,
                                 this, &NetworkManagerSource::schedule);
    }
    m_state->publishLive(QStringLiteral("network.enabled"), enabled);
    m_state->publishLive(QStringLiteral("network.connected"), connected);
    m_state->publishLive(QStringLiteral("network.internet"), internet && connected);
    m_state->publishLive(QStringLiteral("network.ssid"), name);
    m_state->publishLive(QStringLiteral("network.strength"), strength);
}
} // namespace klde
