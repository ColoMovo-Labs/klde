// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QCoreApplication>
#include <QGuiApplication>
#include <QKeyEvent>
#include <QQmlEngine>
#include <QScopedValueRollback>
#include <QWindow>
#include <algorithm>

namespace klde {
ShellServices *ShellServices::create(QQmlEngine *engine, QJSEngine *) {
    auto *services = new ShellServices(nullptr);
    engine->addImageProvider("applications",
                             new ApplicationIconProvider(services->desktopApplications()));
    if (engine->property("owodeSystemApplications").toBool()) {
        services->m_systemTime = std::make_unique<SystemTimeBackend>();
        services->m_applications.replaceSystemApplications({});
        services->m_desktopApplications.setLocale(services->language()->locale());
        services->m_desktopApplications.start();
        if (engine->property("owodeNativeWindowManager").toBool()) {
            services->m_liveWindowManager = std::make_unique<KWinWindowManagerBackend>();
            auto *manager = services->m_liveWindowManager.get();
            connect(manager, &WindowManagerBackend::windowsChanged, services,
                    &ShellServices::reconcileWindows);
            connect(manager, &WindowManagerBackend::requestRejected, services,
                    &ShellServices::showNotice);
            manager->start();
        }
    }
    return services;
}
ShellServices::ShellServices(QObject *parent)
    : QObject(parent), m_dockApplications(&m_applications), m_search(&m_applications),
      m_scenes(&m_system, &m_blur), m_shortcuts(this), m_mockScenarios(&m_state), m_time(&m_state),
      m_telemetry(&m_state), m_wallpaperEffects(&m_state), m_waydroid(&m_state) {
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
        m_desktopApplications.setLocale(m_language.locale());
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
        if (m_syncing || !m_applications.preview())
            return;
        QScopedValueRollback guard(m_syncing, true);
        m_state.requestValue("activeApp", m_applications.activeId());
    });
    connect(&m_desktopApplications, &DesktopApplicationBackend::catalogChanged, this, [this] {
        m_applications.replaceSystemApplications(m_desktopApplications.entries());
        reconcileWindows();
    });
    connect(&m_applications, &ApplicationModel::pinRequested, &m_desktopApplications,
            &DesktopApplicationBackend::setPinned);
    connect(&m_desktopApplications, &DesktopApplicationBackend::launchFinished, this,
            [this](const QString &id, bool success, const QString &message) {
                showNotice(
                    success
                        ? tr("Started %1").arg(m_applications.nameFor(id))
                        : tr("Could not start %1: %2").arg(m_applications.nameFor(id), message));
            });
    connect(&m_scenes, &PowerSceneController::currentChanged, this, [this] {
        if (m_syncing)
            return;
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
        const bool saver = scene == "power-saver", performance = scene == "performance";
        if (m_state.value("capabilities.cpuPolicy").toBool())
            m_state.requestValue("policy.frequency", saver ? 55 : performance ? 100 : 85);
        if (m_state.value("capabilities.gpuPolicy").toBool())
            m_state.requestValue("policy.gpu",
                                 performance && m_state.value("capabilities.discreteGpu").toBool()
                                     ? "hybrid"
                                     : "integrated");
        if (m_state.value("capabilities.refreshRate").toBool())
            m_state.requestValue("policy.refreshRate", saver ? 60 : performance ? 120 : 90);
        if (m_state.value("capabilities.brightness").toBool())
            m_state.requestValue("policy.brightness", saver ? "dim" : "adaptive");
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
    if (all || path == "notifications.count" || path == "battery.percent" ||
        path == "battery.charging" || path == "cpu.temperature" || path == "sessionError") {
        const auto alerts = m_state.alerts();
        const QString context = m_state.value("sessionError").toBool() ? QStringLiteral("session")
                                : alerts.value("battery").toInt() == 2 ? QStringLiteral("battery")
                                : alerts.value("temperature").toInt() == 2
                                    ? QStringLiteral("temperature")
                                    : QString();
        m_notifications.seedDemo(m_state.value("notifications.count").toInt(), context);
    }
    if (all || path.startsWith("waydroid.")) {
        m_applications.setAndroidSource(m_state.value("waydroid.available").toBool() &&
                                        m_state.value("waydroid.indexApps").toBool());
        if ((!m_state.value("waydroid.available").toBool() ||
             !m_state.value("waydroid.indexApps").toBool() ||
             !m_state.value("waydroid.running").toBool()) &&
            m_state.value("activeApp") == "android-sketch") {
            m_state.requestValue("activeApp", QStringLiteral("desktop"));
            m_applications.resetPreview(QStringLiteral("desktop"));
        }
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
    if (event->type() == QEvent::FocusOut || event->type() == QEvent::WindowDeactivate) {
        m_metaDown = false;
        m_metaUsed = false;
        return false;
    }
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
    if (!m_applications.preview()) {
        if (m_liveWindowManager) {
            const auto windows = m_liveWindowManager->windows();
            // Stacking order is bottom to top. Prefer the most recent visible
            // instance; the compositor, not a successful spawn, confirms focus.
            for (auto window = windows.crbegin(); window != windows.crend(); ++window) {
                const auto data = window->toMap();
                if (windowApplication(data) == appId)
                    return m_liveWindowManager->activateWindow(data.value("id").toString());
            }
        }
        if (m_desktopApplications.launch(appId))
            return true;
        showNotice(tr("That application is unavailable"));
        return false;
    }
    if (appId == "android-sketch" && !m_waydroid.state().value("running").toBool()) {
        showNotice(tr("Preview: start the Android session first"));
        return false;
    }
    if (!m_applications.activate(appId)) {
        showNotice(tr("That application is unavailable"));
        return false;
    }
    showNotice(tr("Preview: %1 is active").arg(m_applications.nameFor(appId)));
    return true;
}
QString ShellServices::windowApplication(const QVariantMap &window) const {
    const auto application = m_desktopApplications.applicationForWindow(
        window.value("applicationId").toString(), window.value("resourceClass").toString(),
        window.value("resourceName").toString());
    return application.isEmpty() ? QStringLiteral("window:") + window.value("id").toString()
                                 : application;
}
void ShellServices::reconcileWindows() {
    if (!m_liveWindowManager)
        return;
    QList<ApplicationEntry> applications;
    const auto windows = m_liveWindowManager->windows();
    for (const auto &item : windows) {
        const auto window = item.toMap();
        const auto id = windowApplication(window);
        auto found = std::find_if(applications.begin(), applications.end(),
                                  [&id](const auto &app) { return app.id == id; });
        if (found == applications.end()) {
            auto name = window.value("title").toString();
            if (name.isEmpty())
                name = window.value("resourceClass").toString();
            if (name.isEmpty())
                name = tr("Application");
            applications.append(
                {id, name, {}, "note", {}, true, window.value("active").toBool(), "window", false});
        } else
            found->active = found->active || window.value("active").toBool();
    }
    m_applications.setRuntimeApplications(applications);
}
void ShellServices::showNotice(const QString &message) {
    m_message = message;
    m_osdValue = -1;
    m_noticeTimer.start();
    emit messageChanged();
}
} // namespace klde
