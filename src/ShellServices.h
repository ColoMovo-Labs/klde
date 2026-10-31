// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "applications/DesktopApplicationBackend.h"
#include "backends/BlurBackend.h"
#include "backends/KWinWindowManagerBackend.h"
#include "backends/MockSystemBackend.h"
#include "backends/MockWindowManagerBackend.h"
#include "backends/PresentationBackends.h"
#include "i18n/LocaleVoiceModel.h"
#include "input/Fcitx5Backend.h"
#include "live/HostTelemetrySource.h"
#include "live/LiveSystemBackend.h"
#include "live/UPowerBatterySource.h"
#include "mock/SystemStateModel.h"
#include "models/ApplicationModel.h"
#include "models/NotificationModel.h"
#include "models/PowerSceneController.h"
#include "platform/common/DisplayServerBackend.h"
#include "platform/common/SessionRuntimeBackend.h"
#include "platform/wayland/NativeSurfaceController.h"
#include "shortcuts/ShortcutRegistry.h"
#include "status/StatusModuleRegistry.h"
#include "weather/WeatherService.h"
#include <QTimer>

class QQmlEngine;
class QJSEngine;

namespace klde {
class ShellServices final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(Shell)
    QML_SINGLETON
    Q_PROPERTY(klde::SystemBackend *system READ system CONSTANT)
    Q_PROPERTY(klde::WindowManagerBackend *windowManager READ windowManager CONSTANT)
    Q_PROPERTY(klde::BlurBackend *blur READ blur CONSTANT)
    Q_PROPERTY(klde::ApplicationModel *applications READ applications CONSTANT)
    Q_PROPERTY(klde::DockApplicationModel *dockApplications READ dockApplications CONSTANT)
    Q_PROPERTY(
        klde::DesktopApplicationBackend *desktopApplications READ desktopApplications CONSTANT)
    Q_PROPERTY(klde::ApplicationFilterModel *search READ search CONSTANT)
    Q_PROPERTY(klde::PowerSceneController *scenes READ scenes CONSTANT)
    Q_PROPERTY(klde::ShortcutRegistry *shortcuts READ shortcuts CONSTANT)
    Q_PROPERTY(QVariantMap weather READ weather NOTIFY weatherChanged)
    Q_PROPERTY(klde::WeatherService *weatherService READ weatherService CONSTANT)
    Q_PROPERTY(klde::LocaleVoiceModel *language READ language CONSTANT)
    Q_PROPERTY(klde::InputMethodBackend *input READ input CONSTANT)
    Q_PROPERTY(klde::DisplayServerBackend *displayServer READ displayServer CONSTANT)
    Q_PROPERTY(klde::SessionRuntimeBackend *session READ session CONSTANT)
    Q_PROPERTY(klde::NativeSurfaceController *surface READ surface CONSTANT)
    Q_PROPERTY(klde::SystemStateModel *state READ state CONSTANT)
    Q_PROPERTY(klde::MockScenarioManager *mockScenarios READ mockScenarios CONSTANT)
    Q_PROPERTY(klde::NotificationModel *notifications READ notifications CONSTANT)
    Q_PROPERTY(klde::StatusModuleRegistry *ribbon READ ribbon CONSTANT)
    Q_PROPERTY(klde::TimeBackend *time READ time CONSTANT)
    Q_PROPERTY(klde::TelemetryBackend *telemetry READ telemetry CONSTANT)
    Q_PROPERTY(klde::WallpaperEffectsBackend *wallpaperEffects READ wallpaperEffects CONSTANT)
    Q_PROPERTY(klde::WaydroidBackend *waydroid READ waydroid CONSTANT)
    Q_PROPERTY(QString message READ message NOTIFY messageChanged)
    Q_PROPERTY(int osdValue READ osdValue NOTIFY messageChanged)
  public:
    explicit ShellServices(QObject *parent);
    static ShellServices *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    SystemBackend *system() {
        if (m_liveSystem)
            return m_liveSystem.get();
        return &m_system;
    }
    WindowManagerBackend *windowManager() {
        if (m_liveWindowManager)
            return m_liveWindowManager.get();
        return &m_windowManager;
    }
    BlurBackend *blur() { return &m_blur; }
    ApplicationModel *applications() { return &m_applications; }
    DockApplicationModel *dockApplications() { return &m_dockApplications; }
    DesktopApplicationBackend *desktopApplications() { return &m_desktopApplications; }
    ApplicationFilterModel *search() { return &m_search; }
    PowerSceneController *scenes() { return &m_scenes; }
    ShortcutRegistry *shortcuts() { return &m_shortcuts; }
    WeatherService *weatherService() { return &m_weather; }
    LocaleVoiceModel *language() { return &m_language; }
    InputMethodBackend *input() { return &m_input; }
    DisplayServerBackend *displayServer() { return &m_displayServer; }
    SessionRuntimeBackend *session() { return &m_session; }
    NativeSurfaceController *surface() { return &m_surface; }
    SystemStateModel *state() { return &m_state; }
    MockScenarioManager *mockScenarios() { return &m_mockScenarios; }
    NotificationModel *notifications() { return &m_notifications; }
    StatusModuleRegistry *ribbon() { return &m_ribbon; }
    Q_INVOKABLE bool previewAction(const QString &action);
    QVariantMap weather() const;
    TimeBackend *time() {
        if (m_systemTime)
            return m_systemTime.get();
        return &m_time;
    }
    TelemetryBackend *telemetry() { return &m_telemetry; }
    WallpaperEffectsBackend *wallpaperEffects() { return &m_wallpaperEffects; }
    WaydroidBackend *waydroid() { return &m_waydroid; }
    QString message() const { return m_message; }
    int osdValue() const { return m_osdValue; }
    Q_INVOKABLE bool launch(const QString &appId);
    Q_INVOKABLE void showNotice(const QString &message);
    void setGraphicsAvailable(bool available) { m_blur.setGraphicsAvailable(available); }
  signals:
    void messageChanged();
    void weatherChanged();
    void launcherRequested();

  protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

  private:
    void projectState(const QString &path = {});
    void reconcileSystem();
    void reconcileWindows();
    QString windowApplication(const QVariantMap &window) const;
    MockSystemBackend m_system;
    MockWindowManagerBackend m_windowManager;
    std::unique_ptr<KWinWindowManagerBackend> m_liveWindowManager;
    PreviewBlurBackend m_blur;
    ApplicationModel m_applications;
    DockApplicationModel m_dockApplications;
    DesktopApplicationBackend m_desktopApplications;
    ApplicationFilterModel m_search;
    PowerSceneController m_scenes;
    ShortcutRegistry m_shortcuts;
    WeatherService m_weather;
    LocaleVoiceModel m_language;
    Fcitx5Backend m_input;
    DisplayServerBackend m_displayServer;
    SessionRuntimeBackend m_session;
    NativeSurfaceController m_surface;
    SystemStateModel m_state;
    MockScenarioManager m_mockScenarios;
    MockTimeBackend m_time;
    std::unique_ptr<SystemTimeBackend> m_systemTime;
    // Live system sources; created only for system/native sessions.
    std::unique_ptr<HostTelemetrySource> m_hostTelemetry;
    std::unique_ptr<UPowerBatterySource> m_battery;
    std::unique_ptr<QObject> m_network;
    std::unique_ptr<QObject> m_bluetooth;
    std::unique_ptr<LiveSystemBackend> m_liveSystem;
    MockTelemetryBackend m_telemetry;
    MockWallpaperEffectsBackend m_wallpaperEffects;
    MockWaydroidBackend m_waydroid;
    NotificationModel m_notifications;
    StatusModuleRegistry m_ribbon;
    bool m_syncing = false;
    bool m_metaDown = false;
    bool m_metaUsed = false;
    QTimer m_noticeTimer;
    QString m_message;
    int m_osdValue = -1;
};
} // namespace klde
