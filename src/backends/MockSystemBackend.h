// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "SystemBackend.h"
#include <QVariantMap>

namespace klde {
class MockSystemBackend final : public SystemBackend {
    Q_OBJECT
  public:
    using SystemBackend::SystemBackend;
    int volume() const override { return m_volume; }
    int brightness() const override { return m_brightness; }
    bool wifi() const override { return m_wifi; }
    bool bluetooth() const override { return m_bluetooth; }
    bool nightMode() const override { return m_nightMode; }
    QString powerProfile() const override { return m_powerProfile; }
    bool mock() const override { return true; }
    void applyPreviewState(const QVariantMap &snapshot);
    void setVolume(int value) override;
    void setBrightness(int value) override;
    void setWifi(bool value) override;
    void setBluetooth(bool value) override;
    void setNightMode(bool value) override;
    void setPowerProfile(const QString &profile) override;
    bool requestSessionAction(const QString &action) override;

  private:
    int m_volume = 42;
    int m_brightness = 76;
    bool m_wifi = true;
    bool m_bluetooth = false;
    bool m_nightMode = false;
    QString m_powerProfile = QStringLiteral("Balanced");
};
} // namespace klde
