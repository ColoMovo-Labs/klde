// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "backends/SystemBackend.h"

namespace klde {
class SystemStateModel;

// The SystemBackend QML sees in native/system sessions. Every control reads
// and writes SystemStateModel's live paths, whose writers reach the real
// services; a value changes only when its service confirms it. Session actions
// remain preview-only until the logind integration lands.
class LiveSystemBackend final : public SystemBackend {
    Q_OBJECT
  public:
    LiveSystemBackend(SystemStateModel *state, SystemBackend *preview, QObject *parent = nullptr);
    int volume() const override;
    int brightness() const override;
    bool wifi() const override;
    bool bluetooth() const override;
    bool nightMode() const override;
    QString powerProfile() const override;
    bool mock() const override { return false; }
    void setVolume(int value) override;
    void setBrightness(int value) override;
    void setWifi(bool value) override;
    void setBluetooth(bool value) override;
    void setNightMode(bool value) override;
    void setPowerProfile(const QString &profile) override;
    bool requestSessionAction(const QString &action) override {
        return m_preview->requestSessionAction(action);
    }
    // Power Scenes use display names; the daemon uses profile identifiers.
    static QString profileId(const QString &displayName);
    static QString profileName(const QString &id);

  private:
    void request(const QString &path, const QVariant &value);
    SystemStateModel *m_state;
    SystemBackend *m_preview;
};
} // namespace klde
