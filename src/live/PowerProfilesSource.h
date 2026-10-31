// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QDBusConnection>
#include <QDBusServiceWatcher>
#include <QObject>
#include <QStringList>
#include <QVariantMap>

namespace klde {
class SystemStateModel;

// Follows power-profiles-daemon (or tuned-ppd, which serves the same API).
// The UPower-namespaced service is preferred; net.hadess is the older name.
// The active profile is the live "powerProfile" path; its writer sets
// ActiveProfile, which the daemon authorizes for the active local session.
class PowerProfilesSource final : public QObject {
    Q_OBJECT
  public:
    explicit PowerProfilesSource(SystemStateModel *state,
                                 QDBusConnection bus = QDBusConnection::systemBus(),
                                 QObject *parent = nullptr);
    void start();
    QStringList profiles() const { return m_profiles; }

  private slots:
    void propertiesChanged(const QString &interface, const QVariantMap &changed,
                           const QStringList &invalidated);

  private:
    void connectTo(int index);
    void refresh();
    void apply(const QVariantMap &properties);
    bool request(const QString &profile);
    SystemStateModel *m_state;
    QDBusConnection m_bus;
    QDBusServiceWatcher m_watcher;
    int m_endpoint = 0;
    QVariantMap m_properties;
    QStringList m_profiles;
};
} // namespace klde
