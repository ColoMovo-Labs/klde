// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QCoreApplication>
#include <QGuiApplication>
#include <QKeyEvent>
#include <QScopedValueRollback>
#include <QWindow>

namespace klde {
ShellServices::ShellServices(QObject *parent)
    : QObject(parent), m_search(&m_applications), m_scenes(&m_system, &m_blur), m_shortcuts(this),
      m_mockScenarios(&m_state) {
    m_noticeTimer.setSingleShot(true);
    m_noticeTimer.setInterval(2400);
    connect(&m_noticeTimer, &QTimer::timeout, this, [this] {
        m_message.clear();
        m_osdValue = -1;
        emit messageChanged();
    });
    connect(&m_system, &SystemBackend::actionReported, this, &ShellServices::showNotice);
    connect(&m_system, &SystemBackend::requestRejected, this, &ShellServices::showNotice);
    connect(&m_windowManager, &WindowManagerBackend::requestRejected, this,
            &ShellServices::showNotice);
    connect(&m_scenes, &PowerSceneController::requestRejected, this, &ShellServices::showNotice);
    connect(&m_weather, &WeatherService::changed, this, &ShellServices::weatherChanged);
    connect(&m_system, &SystemBackend::osdRequested, this, [this](const QString &kind, int value) {
        showNotice(kind == "volume" ? tr("Volume") : tr("Brightness"));
        m_osdValue = value;
        emit messageChanged();
    });
    connect(&m_state, &SystemStateModel::valueEdited, this, &ShellServices::projectState);
    connect(&m_mockScenarios, &MockScenarioManager::applied, this, [this] { projectState(); });
    connect(&m_system, &SystemBackend::stateChanged, this, &ShellServices::reconcileSystem);
    connect(&m_language, &LocaleVoiceModel::changed, this, [this] {
        if (m_syncing)
            return;
        QScopedValueRollback guard(m_syncing, true);
        m_state.requestValue("locale", m_language.locale());
        m_state.requestValue("voice", m_language.voice());
    });
    connect(&m_input, &InputMethodBackend::changed, this, [this] {
        if (!m_syncing)
            m_state.requestValue("input.currentId", m_input.currentId());
    });
    connect(&m_notifications, &NotificationModel::countChanged, this, [this] {
        if (m_syncing)
            return;
        QScopedValueRollback guard(m_syncing, true);
        m_state.requestValue("notifications.count", m_notifications.count());
    });
    connect(&m_applications, &ApplicationModel::activeChanged, this, [this] {
        if (m_syncing)
            return;
        QScopedValueRollback guard(m_syncing, true);
        m_state.requestValue("activeApp", m_applications.activeId());
    });
    connect(&m_scenes, &PowerSceneController::currentChanged, this, [this] {
        if (m_syncing)
            return;
        QScopedValueRollback guard(m_syncing, true);
        m_state.requestValue("powerScene", m_scenes.activeId());
    });
    connect(&m_windowManager, &WindowManagerBackend::activeWorkspaceChanged, this, [this] {
        if (m_syncing)
            return;
        QScopedValueRollback guard(m_syncing, true);
        m_state.requestValue("workspaces.active",
                             m_windowManager.activeWorkspace().mid(10).toInt());
    });
    projectState();
    if (qobject_cast<QGuiApplication *>(QCoreApplication::instance()))
        QCoreApplication::instance()->installEventFilter(this);
}
void ShellServices::reconcileSystem() {
    if (m_syncing)
        return;
    QScopedValueRollback guard(m_syncing, true);
    m_state.requestValue("audio.volume", m_system.volume());
    m_state.requestValue("brightness", m_system.brightness());
    m_state.requestValue("network.enabled", m_system.wifi());
    if (!m_system.wifi()) {
        m_state.requestValue("network.connected", false);
        m_state.requestValue("network.internet", false);
    }
    m_state.requestValue("bluetooth.enabled", m_system.bluetooth());
    m_state.requestValue("nightMode", m_system.nightMode());
}
void ShellServices::projectState(const QString &path) {
    if (m_syncing)
        return;
    QScopedValueRollback guard(m_syncing, true);
    const bool all = path.isEmpty();
    if (all || path.startsWith("audio.") || path.startsWith("network.") ||
        path.startsWith("bluetooth.") || path == "brightness" || path == "nightMode")
        m_system.applyPreviewState(m_state.snapshot());
    if (all || path == "locale")
        m_language.setLocale(m_state.value("locale").toString());
    if (all || path == "voice")
        m_language.setVoice(m_state.value("voice").toString());
    if (all || path == "input.currentId")
        m_input.selectPreview(m_state.value("input.currentId").toString());
    if (all)
        m_scenes.resetDefaults();
    if (all || path == "powerScene") {
        m_scenes.select(m_state.value("powerScene").toString());
        const auto scene = m_scenes.activeId();
        m_state.requestValue("policy.cpu", scene == "power-saver"   ? "efficient"
                                           : scene == "performance" ? "performance"
                                                                    : "balanced");
    }
    if (all && m_state.value("nightMode").toBool())
        m_scenes.customize("theme", QStringLiteral("dark"));
    if (all || path.startsWith("weather.")) {
        WeatherReading reading;
        reading.location = m_state.value("weather.city").toString();
        reading.condition = m_state.value("weather.condition").toString().replace('-', ' ');
        reading.category = normalizeWeatherCondition(reading.condition);
        reading.temperature = m_state.value("weather.temperature").toDouble();
        reading.fetchedAt = QDateTime::fromString(m_state.value("time").toString(), Qt::ISODate);
        m_weather.applyPreview(reading, m_state.value("weather.available").toBool());
    }
    if (all || path == "notifications.count") {
        const QString context =
            m_state.value("sessionError").toBool()           ? QStringLiteral("session")
            : m_state.value("battery.percent").toInt() <= 5  ? QStringLiteral("battery")
            : m_state.value("cpu.temperature").toInt() >= 92 ? QStringLiteral("temperature")
                                                             : QString();
        m_notifications.seedDemo(m_state.value("notifications.count").toInt(), context);
    }
    if (all || path == "activeApp")
        m_applications.resetPreview(m_state.value("activeApp").toString());
    if (all || path == "workspaces.layouts")
        m_windowManager.resetPreview(m_state.value("workspaces.layouts").toList(),
                                     m_state.value("workspaces.active").toInt());
    else if (path == "workspaces.active")
        m_windowManager.activateWorkspace(
            QStringLiteral("workspace-%1").arg(m_state.value(path).toInt()));
}
bool ShellServices::previewAction(const QString &action) {
    if (action.startsWith("workspace.") || action.startsWith("move.")) {
        const int number = action.section('.', 1).toInt();
        if (number < 1 || number > 5)
            return false;
        const auto id = QStringLiteral("workspace-%1").arg(number);
        return action.startsWith("move.")
                   ? m_windowManager.moveWindow(QStringLiteral("demo-terminal"), id)
                   : m_windowManager.activateWorkspace(id);
    }
    if (action == "window.float") {
        const auto windows = m_windowManager.windows();
        if (windows.isEmpty())
            return false;
        return m_windowManager.setWindowFloating(
            QStringLiteral("demo-terminal"), !windows.first().toMap().value("floating").toBool());
    }
    if (action == "window.close") {
        m_state.requestValue("activeApp", QStringLiteral("desktop"));
        showNotice(tr("Preview window closed. Host applications are unchanged."));
        return true;
    }
    if (action == "shell.scratchpad")
        return m_state.requestValue("scratchpad", !m_state.value("scratchpad").toBool());
    if (action == "shell.media")
        return m_state.requestValue("media.playing", !m_state.value("media.playing").toBool());
    return false;
}
bool ShellServices::eventFilter(QObject *watched, QEvent *event) {
    if (!qobject_cast<QWindow *>(watched))
        return false;
    if (event->type() == QEvent::KeyPress || event->type() == QEvent::KeyRelease) {
        const auto *key = static_cast<QKeyEvent *>(event);
        if (key->isAutoRepeat())
            return false;
        if (event->type() == QEvent::KeyPress) {
            if (key->key() == Qt::Key_Meta) {
                m_metaDown = true;
                m_metaUsed = false;
            } else if (m_metaDown)
                m_metaUsed = true;
        } else if (key->key() == Qt::Key_Meta) {
            if (m_metaDown && !m_metaUsed)
                emit launcherRequested();
            m_metaDown = false;
        }
    }
    return false;
}
QVariantMap ShellServices::weather() const { return m_weather.reading(); }
bool ShellServices::launch(const QString &appId) {
    if (!m_applications.activate(appId)) {
        showNotice(tr("That application is unavailable"));
        return false;
    }
    showNotice(tr("Preview: %1 is active").arg(m_applications.nameFor(appId)));
    return true;
}
void ShellServices::showNotice(const QString &message) {
    m_message = message;
    m_osdValue = -1;
    m_noticeTimer.start();
    emit messageChanged();
}
} // namespace klde
