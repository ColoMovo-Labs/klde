// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QDBusConnection>
#include <QDBusServiceWatcher>
#include <QObject>
#include <QVariantMap>

namespace klde {
class SystemStateModel;

// Projects UPower's composite display device into live battery state. The
// initial snapshot is fetched asynchronously, then PropertiesChanged signals
// keep it current; a restarted UPower is re-read through the owner watcher.
class UPowerBatterySource final : public QObject {
    Q_OBJECT
  public:
    explicit UPowerBatterySource(SystemStateModel *state,
                                 QDBusConnection bus = QDBusConnection::systemBus(),
                                 QObject *parent = nullptr);
    void start();
    // UPower DeviceType 2 is a battery; states 1 and 4/5 are charging/full/pending.
    static QVariantMap project(const QVariantMap &properties);

  private slots:
    void propertiesChanged(const QString &interface, const QVariantMap &changed,
                           const QStringList &invalidated);

  private:
    void refresh();
    void apply(const QVariantMap &properties);
    SystemStateModel *m_state;
    QDBusConnection m_bus;
    QDBusServiceWatcher m_watcher;
    QVariantMap m_properties;
};
} // namespace klde
