// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "backends/BlurBackend.h"
#include "backends/MockSystemBackend.h"
#include "backends/MockWindowManagerBackend.h"
#include "models/ApplicationModel.h"
#include "models/PowerSceneController.h"
#include "shortcuts/ShortcutRegistry.h"
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
    QVariantMap weather() const;
    QString message() const { return m_message; }
    int osdValue() const { return m_osdValue; }
    Q_INVOKABLE bool launch(const QString &appId);
    Q_INVOKABLE void showNotice(const QString &message);
    void setGraphicsAvailable(bool available) { m_blur.setGraphicsAvailable(available); }
  signals:
    void messageChanged();
    void weatherChanged();

  private:
    MockSystemBackend m_system;
    MockWindowManagerBackend m_windowManager;
    PreviewBlurBackend m_blur;
    ApplicationModel m_applications;
    ApplicationFilterModel m_search;
    PowerSceneController m_scenes;
    ShortcutRegistry m_shortcuts;
    WeatherService m_weather;
    QTimer m_noticeTimer;
    QString m_message;
    int m_osdValue = -1;
};
} // namespace klde
