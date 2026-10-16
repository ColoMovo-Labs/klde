// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "InputMethodBackend.h"
#include <QDBusServiceWatcher>

namespace klde {
class Fcitx5Backend final : public InputMethodBackend {
    Q_OBJECT
  public:
    explicit Fcitx5Backend(QObject *parent = nullptr);
    bool engineAvailable() const override { return m_available; }
    bool simulated() const override { return true; }
    bool switchingSupported() const override { return false; }
    QString currentId() const override { return m_current; }
    QString indicator() const override {
        return m_current == "pinyin" ? QStringLiteral("拼") : QStringLiteral("EN");
    }
    QVariantList methods() const override;
    bool requestSwitch(const QString &id) override;
    bool selectPreview(const QString &id) override;

  private:
    void setAvailable(bool available);
    QDBusServiceWatcher m_watcher;
    QString m_current = QStringLiteral("keyboard-us");
    int m_ownerGeneration = 0;
    bool m_available = false;
};
} // namespace klde
