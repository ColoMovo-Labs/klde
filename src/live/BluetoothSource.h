// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QTimer>

namespace BluezQt {
class Manager;
}

namespace klde {
class SystemStateModel;

// Projects BlueZ adapters and connected devices into live Bluetooth state and
// routes the Bluetooth switch to adapter power (unblocking rfkill first).
class BluetoothSource final : public QObject {
    Q_OBJECT
  public:
    explicit BluetoothSource(SystemStateModel *state, QObject *parent = nullptr);
    ~BluetoothSource() override;
    void start();

  private:
    void schedule() { m_refresh.start(); }
    void refresh();
    bool setEnabled(bool enabled);
    SystemStateModel *m_state;
    BluezQt::Manager *m_manager = nullptr;
    QTimer m_refresh;
    bool m_ready = false;
};
} // namespace klde
