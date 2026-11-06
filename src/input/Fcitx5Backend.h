// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "InputMethodBackend.h"
#include <QDBusConnection>
#include <QDBusServiceWatcher>
#include <QTimer>

namespace klde {
class Fcitx5Backend final : public InputMethodBackend {
    Q_OBJECT
  public:
    explicit Fcitx5Backend(QObject *parent = nullptr);
    void start();
    bool configure() override;
    bool engineAvailable() const override { return m_available; }
    bool simulated() const override { return !m_native; }
    bool switchingSupported() const override { return m_native && m_ready && !m_switching; }
    QString currentId() const override { return m_current; }
    QString indicator() const override;
    QVariantList methods() const override;
    bool requestSwitch(const QString &id) override;
    bool selectPreview(const QString &id) override;
  public slots:
    void refresh() override;

  private:
    void setOwner(const QString &owner);
    void query();
    void finishQuery(int generation, bool success);
    QDBusConnection m_bus;
    QDBusServiceWatcher m_watcher;
    QTimer m_refresh;
    QVariantList m_methods;
    QString m_owner;
    QString m_current = QStringLiteral("keyboard-us");
    int m_ownerGeneration = 0;
    bool m_native = false, m_available = false, m_ready = false;
    bool m_pending = false, m_refreshAgain = false, m_switching = false;
};
} // namespace klde
