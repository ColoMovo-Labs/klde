// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "backends/SystemBackend.h"

namespace klde {
class SystemStateModel;

// The SystemBackend QML sees in native/system sessions. Controls that have a
// live service read and write through SystemStateModel's live paths; the rest
// are delegated to the preview backend until their service is integrated, so
// mock() stays true while any delegated control remains.
class LiveSystemBackend final : public SystemBackend {
    Q_OBJECT
  public:
    LiveSystemBackend(SystemStateModel *state, SystemBackend *preview, QObject *parent = nullptr);
    int volume() const override { return m_preview->volume(); }
    int brightness() const override { return m_preview->brightness(); }
    bool wifi() const override;
    bool bluetooth() const override;
    bool nightMode() const override { return m_preview->nightMode(); }
    QString powerProfile() const override { return m_preview->powerProfile(); }
    bool mock() const override { return true; }
    void setVolume(int value) override { m_preview->setVolume(value); }
    void setBrightness(int value) override { m_preview->setBrightness(value); }
    void setWifi(bool value) override;
    void setBluetooth(bool value) override;
    void setNightMode(bool value) override { m_preview->setNightMode(value); }
    void setPowerProfile(const QString &profile) override { m_preview->setPowerProfile(profile); }
    bool requestSessionAction(const QString &action) override {
        return m_preview->requestSessionAction(action);
    }

  private:
    void request(const QString &path, bool value);
    SystemStateModel *m_state;
    SystemBackend *m_preview;
};
} // namespace klde
