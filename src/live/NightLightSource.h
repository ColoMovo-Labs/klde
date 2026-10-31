// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QDBusConnection>
#include <QDBusServiceWatcher>
#include <QObject>
#include <QVariantMap>

namespace klde {
class SystemStateModel;

// Follows KWin's Night Light over the session bus. The switch writes KWin's
// own configuration (NightColor/Active, constant mode when enabling) and asks
// KWin to reconfigure; the state changes once KWin reports it.
class NightLightSource final : public QObject {
    Q_OBJECT
  public:
    explicit NightLightSource(SystemStateModel *state,
                              QDBusConnection bus = QDBusConnection::sessionBus(),
                              QObject *parent = nullptr);
    void start();

  private slots:
    void propertiesChanged(const QString &interface, const QVariantMap &changed,
                           const QStringList &invalidated);

  private:
    void refresh();
    void apply(const QVariantMap &properties);
    bool request(bool enabled);
    SystemStateModel *m_state;
    QDBusConnection m_bus;
    QDBusServiceWatcher m_watcher;
    QVariantMap m_properties;
};
} // namespace klde
