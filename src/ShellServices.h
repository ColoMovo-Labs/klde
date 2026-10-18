// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "backends/BlurBackend.h"
#include "backends/MockSystemBackend.h"
#include "backends/MockWindowManagerBackend.h"
#include "backends/PresentationBackends.h"
#include "i18n/LocaleVoiceModel.h"
#include "input/Fcitx5Backend.h"
#include "mock/SystemStateModel.h"
#include "models/ApplicationModel.h"
#include "models/NotificationModel.h"
#include "models/PowerSceneController.h"
#include "platform/common/DisplayServerBackend.h"
#include "platform/common/SessionRuntimeBackend.h"
#include "shortcuts/ShortcutRegistry.h"
#include "status/StatusModuleRegistry.h"
#include "weather/WeatherService.h"
#include <QTimer>

namespace klde {
class ShellServices final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(Shell)
    QML_SINGLETON
    Q_PROPERTY(klde::SystemBackend *system READ system CONSTANT)
    Q_PROPERTY(klde::WindowManagerBackend *windowManager READ windowManager CONSTANT)
    Q_PROPERTY(klde::BlurBackend *blur READ blur CONSTANT)
    Q_PROPERTY(klde::ApplicationModel *applications READ applications CONSTANT)
    Q_PROPERTY(klde::ApplicationFilterModel *search READ search CONSTANT)
    Q_PROPERTY(klde::PowerSceneController *scenes READ scenes CONSTANT)
    Q_PROPERTY(klde::ShortcutRegistry *shortcuts READ shortcuts CONSTANT)
    Q_PROPERTY(QVariantMap weather READ weather NOTIFY weatherChanged)
    Q_PROPERTY(klde::WeatherService *weatherService READ weatherService CONSTANT)
    Q_PROPERTY(klde::LocaleVoiceModel *language READ language CONSTANT)
    Q_PROPERTY(klde::InputMethodBackend *input READ input CONSTANT)
    Q_PROPERTY(klde::DisplayServerBackend *displayServer READ displayServer CONSTANT)
    Q_PROPERTY(klde::SessionRuntimeBackend *session READ session CONSTANT)
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
    explicit ShellServices(QObject *parent = nullptr);
    SystemBackend *system() { return &m_system; }
    WindowManagerBackend *windowManager() { return &m_windowManager; }
    BlurBackend *blur() { return &m_blur; }
    ApplicationModel *applications() { return &m_applications; }
    ApplicationFilterModel *search() { return &m_search; }
    PowerSceneController *scenes() { return &m_scenes; }
    ShortcutRegistry *shortcuts() { return &m_shortcuts; }
    WeatherService *weatherService() { return &m_weather; }
    LocaleVoiceModel *language() { return &m_language; }
    InputMethodBackend *input() { return &m_input; }
    DisplayServerBackend *displayServer() { return &m_displayServer; }
    SessionRuntimeBackend *session() { return &m_session; }
    SystemStateModel *state() { return &m_state; }
    MockScenarioManager *mockScenarios() { return &m_mockScenarios; }
    NotificationModel *notifications() { return &m_notifications; }
    StatusModuleRegistry *ribbon() { return &m_ribbon; }
    Q_INVOKABLE bool previewAction(const QString &action);
    QVariantMap weather() const;
    TimeBackend *time() { return &m_time; }
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
    MockSystemBackend m_system;
    MockWindowManagerBackend m_windowManager;
    PreviewBlurBackend m_blur;
    ApplicationModel m_applications;
    ApplicationFilterModel m_search;
    PowerSceneController m_scenes;
    ShortcutRegistry m_shortcuts;
    WeatherService m_weather;
    LocaleVoiceModel m_language;
    Fcitx5Backend m_input;
    DisplayServerBackend m_displayServer;
    SessionRuntimeBackend m_session;
    SystemStateModel m_state;
    MockScenarioManager m_mockScenarios;
    MockTimeBackend m_time;
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
