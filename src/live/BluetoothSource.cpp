// SPDX-License-Identifier: GPL-3.0-or-later
#include "BluetoothSource.h"
#include "mock/SystemStateModel.h"
#include <BluezQt/Adapter>
#include <BluezQt/Device>
#include <BluezQt/InitManagerJob>
#include <BluezQt/Manager>
#include <algorithm>

namespace klde {
BluetoothSource::BluetoothSource(SystemStateModel *state, QObject *parent)
    : QObject(parent), m_state(state), m_manager(new BluezQt::Manager(this)) {
    m_refresh.setSingleShot(true);
    m_refresh.setInterval(0);
    connect(&m_refresh, &QTimer::timeout, this, &BluetoothSource::refresh);
}

BluetoothSource::~BluetoothSource() = default;

void BluetoothSource::start() {
    // Until BlueZ answers, Bluetooth is unavailable rather than a fixture.
    m_state->publishLive(QStringLiteral("capabilities.bluetooth"), false);
    m_state->publishLive(QStringLiteral("bluetooth.enabled"), false);
    m_state->publishLive(QStringLiteral("bluetooth.connectedDevices"), 0);
    m_state->setLiveWriter(QStringLiteral("bluetooth.enabled"),
                           [this](const QVariant &value) { return setEnabled(value.toBool()); });
    for (const auto signal :
         {&BluezQt::Manager::operationalChanged, &BluezQt::Manager::bluetoothOperationalChanged,
          &BluezQt::Manager::bluetoothBlockedChanged})
        connect(m_manager, signal, this, &BluetoothSource::schedule);
    connect(m_manager, &BluezQt::Manager::adapterAdded, this, &BluetoothSource::schedule);
    connect(m_manager, &BluezQt::Manager::adapterRemoved, this, &BluetoothSource::schedule);
    connect(m_manager, &BluezQt::Manager::adapterChanged, this, &BluetoothSource::schedule);
    connect(m_manager, &BluezQt::Manager::usableAdapterChanged, this, &BluetoothSource::schedule);
    connect(m_manager, &BluezQt::Manager::deviceAdded, this, &BluetoothSource::schedule);
    connect(m_manager, &BluezQt::Manager::deviceRemoved, this, &BluetoothSource::schedule);
    connect(m_manager, &BluezQt::Manager::deviceChanged, this, &BluetoothSource::schedule);
    auto *job = m_manager->init();
    connect(job, &BluezQt::InitManagerJob::result, this, [this](BluezQt::InitManagerJob *done) {
        m_ready = !done->error();
        refresh();
    });
    job->start();
}

bool BluetoothSource::setEnabled(bool enabled) {
    if (!m_ready || m_manager->adapters().isEmpty())
        return false;
    if (enabled && m_manager->isBluetoothBlocked())
        m_manager->setBluetoothBlocked(false);
    for (const auto &adapter : m_manager->adapters())
        adapter->setPowered(enabled);
    return true;
}

void BluetoothSource::refresh() {
    const bool present = m_ready && m_manager->isOperational() && !m_manager->adapters().isEmpty();
    const bool enabled = present && m_manager->isBluetoothOperational();
    const auto devices = m_manager->devices();
    const auto connected =
        enabled
            ? std::count_if(devices.cbegin(), devices.cend(),
                            [](const BluezQt::DevicePtr &device) { return device->isConnected(); })
            : 0;
    m_state->publishLive(QStringLiteral("capabilities.bluetooth"), present);
    m_state->publishLive(QStringLiteral("bluetooth.enabled"), enabled);
    m_state->publishLive(QStringLiteral("bluetooth.connectedDevices"),
                         static_cast<int>(std::min<qsizetype>(connected, 100)));
}
} // namespace klde
