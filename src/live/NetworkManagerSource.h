// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QMetaObject>
#include <QObject>
#include <QString>
#include <QTimer>

namespace klde {
class SystemStateModel;

// Projects NetworkManager into live network state and routes the Wi-Fi switch
// to it. Notifier signals are coalesced into one recomputation per event loop
// turn; the current access point is followed for signal strength.
class NetworkManagerSource final : public QObject {
    Q_OBJECT
  public:
    explicit NetworkManagerSource(SystemStateModel *state, QObject *parent = nullptr);
    void start();
    // Network-provided names are untrusted: keep printable text, bounded length.
    static QString displayName(const QString &raw);

  private:
    void schedule() { m_refresh.start(); }
    void refresh();
    bool setEnabled(bool enabled);
    SystemStateModel *m_state;
    QTimer m_refresh;
    QMetaObject::Connection m_strength;
    QString m_accessPoint;
    bool m_hasWifi = false;
};
} // namespace klde
