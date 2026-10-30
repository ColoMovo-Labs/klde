// SPDX-License-Identifier: GPL-3.0-or-later
#include "KWinWindowManagerBackend.h"
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QFile>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSet>
#include <QUuid>
#include <algorithm>
#include <utility>

static void initializeKWinScripts() { Q_INIT_RESOURCE(owode_kwin_scripts); }

namespace klde {
namespace {
QString jsonString(const QString &text) {
    const auto array = QJsonDocument(QJsonArray{text}).toJson(QJsonDocument::Compact);
    return QString::fromUtf8(array.mid(1, array.size() - 2));
}
QDBusMessage scriptingCall(const QString &owner, const QString &method) {
    return QDBusMessage::createMethodCall(owner, "/Scripting", "org.kde.kwin.Scripting", method);
}
bool validId(const QString &id) {
    static const QRegularExpression uuid(
        QStringLiteral(R"(^\{?[a-fA-F0-9]{8}(?:-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}\}?$)"));
    return uuid.match(id).hasMatch();
}
} // namespace

KWinWindowManagerBackend::KWinWindowManagerBackend(QObject *parent)
    : WindowManagerBackend(parent), m_watcher("org.kde.KWin", QDBusConnection::sessionBus(),
                                              QDBusServiceWatcher::WatchForOwnerChange, this) {
    initializeKWinScripts();
    m_objectPath = "/org/owode/KWinBridge/i" + QUuid::createUuid().toString(QUuid::Id128);
    m_deadline.setSingleShot(true);
    m_deadline.setInterval(10000);
    connect(&m_deadline, &QTimer::timeout, this, [this] {
        unloadScript(m_owner, m_reporter);
        m_reporter.clear();
        clearState(QStringLiteral("KWin scripting handshake timed out"));
    });
    connect(
        &m_watcher, &QDBusServiceWatcher::serviceOwnerChanged, this,
        [this](const QString &, const QString &, const QString &owner) { ownerChanged(owner); });
}
KWinWindowManagerBackend::~KWinWindowManagerBackend() {
    unloadScript(m_owner, m_reporter);
    for (const auto &name : std::as_const(m_commands))
        unloadScript(m_owner, name);
    if (m_registered)
        QDBusConnection::sessionBus().unregisterObject(m_objectPath);
}
void KWinWindowManagerBackend::invoke(const QDBusMessage &message,
                                      std::function<void(const QDBusMessage &)> handler) {
    auto pending = std::make_unique<QDBusPendingCallWatcher>(
        QDBusConnection::sessionBus().asyncCall(message, 3000));
    auto *watcher = pending.get();
    m_pending.push_back(std::move(pending));
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, handler = std::move(handler)](QDBusPendingCallWatcher *finished) {
                const auto result = finished->reply();
                QTimer::singleShot(0, this, [this, finished] {
                    std::erase_if(m_pending, [finished](const auto &entry) {
                        return entry.get() == finished;
                    });
                });
                handler(result);
            });
}
QString KWinWindowManagerBackend::scriptSource(const QString &file) const {
    QFile source(QStringLiteral(":/owode/") + file);
    if (!source.open(QIODevice::ReadOnly))
        return {};
    return QString::fromUtf8(source.readAll())
        .replace("@DESTINATION@", jsonString(QDBusConnection::sessionBus().baseService()))
        .replace("@OBJECT_PATH@", jsonString(m_objectPath))
        .replace("@TOKEN@", jsonString(m_token));
}
void KWinWindowManagerBackend::start() {
    if (m_started)
        return;
    m_started = true;
    auto bus = QDBusConnection::sessionBus();
    if (QGuiApplication::platformName() != "wayland" || !m_scripts.isValid() ||
        !bus.registerObject(m_objectPath, this, QDBusConnection::ExportScriptableSlots)) {
        clearState(QStringLiteral("Wayland and a private scripting callback are required"));
        return;
    }
    m_registered = true;
    auto message = QDBusMessage::createMethodCall("org.freedesktop.DBus", "/org/freedesktop/DBus",
                                                  "org.freedesktop.DBus", "GetNameOwner");
    message << QStringLiteral("org.kde.KWin");
    const auto generation = m_generation;
    invoke(message, [this, generation](const QDBusMessage &response) {
        const QDBusPendingReply<QString> reply = response;
        if (generation == m_generation)
            ownerChanged(reply.isError() ? QString{} : reply.value());
    });
}
void KWinWindowManagerBackend::ownerChanged(const QString &owner) {
    if (!m_registered)
        return;
    ++m_generation;
    m_deadline.stop();
    unloadScript(m_owner, m_reporter);
    for (const auto &name : std::as_const(m_commands))
        unloadScript(m_owner, name);
    m_commands.clear();
    m_reporter.clear();
    m_owner = owner;
    m_version.clear();
    m_sequence = 0;
    m_token = QUuid::createUuid().toString(QUuid::Id128);
    clearState(owner.isEmpty() ? QStringLiteral("KWin is unavailable")
                               : QStringLiteral("Probing KWin scripting capabilities"));
    if (owner.isEmpty())
        return;
    const auto generation = m_generation;
    const auto message =
        QDBusMessage::createMethodCall(owner, "/KWin", "org.kde.KWin", "supportInformation");
    invoke(message, [this, generation](const QDBusMessage &response) {
        const QDBusPendingReply<QString> reply = response;
        if (generation != m_generation)
            return;
        const QRegularExpression version(
            QStringLiteral(R"(^KWin version: (6\.(6|7)\.\d+)[^\r\n]*$)"),
            QRegularExpression::MultilineOption);
        const auto match = version.match(reply.isError() ? QString{} : reply.value());
        if (!match.hasMatch()) {
            clearState(QStringLiteral("Only probed upstream KWin 6.6/6.7 profiles are enabled"));
            return;
        }
        m_version = match.captured(1);
        m_reporter = "owode-state-" + m_token;
        m_deadline.start();
        loadScript(m_reporter, true, scriptSource("kwin-state.js").toUtf8());
    });
}
void KWinWindowManagerBackend::clearState(const QString &diagnostic) {
    m_ready = false;
    m_diagnostic = diagnostic;
    m_workspaces.clear();
    m_windows.clear();
    m_activeWorkspace.clear();
    emit workspacesChanged();
    emit windowsChanged();
    emit activeWorkspaceChanged();
    emit capabilitiesChanged();
}
QVariantMap KWinWindowManagerBackend::capabilities() const {
    return {{"mock", false},
            {"available", m_ready},
            {"engine", "upstream-kwin6-script"},
            {"engineVersion", m_version},
            {"diagnostic", m_diagnostic},
            {"workspaceActivation", m_ready},
            {"windowActivation", m_ready},
            {"windowClose", m_ready},
            {"moveWindow", m_ready},
            {"workspaceLayouts", false},
            {"perWindowFloating", false},
            {"windowRules", false},
            {"rememberGeometry", false},
            {"scrollingTiling", false}};
}
void KWinWindowManagerBackend::loadScript(const QString &name, bool reporter,
                                          const QByteArray &source) {
    const auto path = m_scripts.filePath(name + ".js");
    QFile file(path);
    if (source.isEmpty() || !file.open(QIODevice::WriteOnly) ||
        file.write(source) != source.size()) {
        if (reporter)
            clearState(QStringLiteral("Could not stage the owned KWin script"));
        else
            emit requestRejected(tr("The window manager could not perform that action"));
        return;
    }
    file.close();
    const auto owner = m_owner;
    const auto generation = m_generation;
    auto message = scriptingCall(owner, "loadScript");
    message << path << name;
    invoke(message, [this, owner, generation, name, reporter](const QDBusMessage &response) {
        const QDBusPendingReply<int> reply = response;
        if (generation != m_generation) {
            unloadScript(owner, name);
            return;
        }
        if (reply.isError() || reply.value() < 0) {
            if (reporter)
                clearState(QStringLiteral("KWin refused the owned state script"));
            else {
                m_commands.remove(name);
                QFile::remove(m_scripts.filePath(name + ".js"));
                emit requestRejected(tr("The window manager could not perform that action"));
            }
            return;
        }
        auto run = QDBusMessage::createMethodCall(
            owner, "/Scripting/Script" + QString::number(reply.value()), "org.kde.kwin.Script",
            "run");
        invoke(run, [this, generation, reporter, name](const QDBusMessage &response) {
            const QDBusPendingReply<> result = response;
            if (generation == m_generation && result.isError()) {
                unloadScript(m_owner, name);
                if (reporter)
                    clearState(QStringLiteral("KWin state script failed to start"));
                else {
                    m_commands.remove(name);
                    emit requestRejected(tr("The window manager could not perform that action"));
                }
            }
        });
    });
}
void KWinWindowManagerBackend::unloadScript(const QString &owner, const QString &name) {
    if (owner.isEmpty() || name.isEmpty())
        return;
    auto message = scriptingCall(owner, "unloadScript");
    message << name;
    QDBusConnection::sessionBus().asyncCall(message, 1000);
}
bool KWinWindowManagerBackend::trusted(const QString &token) const {
    return calledFromDBus() && message().service() == m_owner && !m_owner.isEmpty() &&
           !m_reporter.isEmpty() && token == m_token;
}
bool KWinWindowManagerBackend::snapshot(const QString &token, const QString &json) {
    if (!trusted(token) || json.toUtf8().size() > 1'048'576)
        return false;
    const auto data = QJsonDocument::fromJson(json.toUtf8()).object();
    const auto desktops = data.value("desktops").toArray();
    const auto windows = data.value("windows").toArray();
    const auto sequence = data.value("sequence").toInteger();
    const auto current = data.value("currentDesktop").toString();
    if (data.value("schema").toInt() != 1 || sequence <= m_sequence || desktops.isEmpty() ||
        desktops.size() > 128 || windows.size() > 2048)
        return false;
    QVariantList nextDesktops;
    QVariantList nextWindows;
    QSet<QString> ids;
    for (const auto &item : desktops) {
        const auto desktop = item.toObject();
        const auto id = desktop.value("id").toString();
        if (!validId(id) || ids.contains(id))
            return false;
        ids.insert(id);
        nextDesktops.append(QVariantMap{{"id", id},
                                        {"name", QString::number(nextDesktops.size() + 1)},
                                        {"displayName", desktop.value("name").toString().left(256)},
                                        {"layout", static_cast<int>(Custom)},
                                        {"layoutKnown", false}});
    }
    if (!ids.contains(current))
        return false;
    QSet<QString> windowIds;
    for (const auto &item : windows) {
        const auto window = item.toObject();
        const auto id = window.value("id").toString();
        if (!validId(id) || windowIds.contains(id))
            return false;
        windowIds.insert(id);
        QStringList membership;
        for (const auto &desktop : window.value("desktops").toArray()) {
            if (!ids.contains(desktop.toString()))
                return false;
            membership.append(desktop.toString());
        }
        nextWindows.append(
            QVariantMap{{"id", id},
                        {"applicationId", window.value("applicationId").toString().left(1024)},
                        {"resourceClass", window.value("resourceClass").toString().left(512)},
                        {"resourceName", window.value("resourceName").toString().left(512)},
                        {"title", window.value("title").toString().left(2048)},
                        {"active", window.value("active").toBool()},
                        {"minimized", window.value("minimized").toBool()},
                        {"closeable", window.value("closeable").toBool()},
                        {"workspaceIds", membership},
                        {"workspaceId", membership.value(0)},
                        {"onAllWorkspaces", membership.isEmpty()}});
    }
    m_sequence = sequence;
    m_deadline.stop();
    const bool newlyReady = !m_ready;
    m_ready = true;
    m_diagnostic.clear();
    if (m_workspaces != nextDesktops) {
        m_workspaces = nextDesktops;
        emit workspacesChanged();
    }
    if (m_windows != nextWindows) {
        m_windows = nextWindows;
        emit windowsChanged();
    }
    if (m_activeWorkspace != current) {
        m_activeWorkspace = current;
        emit activeWorkspaceChanged();
    }
    if (newlyReady)
        emit capabilitiesChanged();
    return true;
}
bool KWinWindowManagerBackend::contains(const QVariantList &items, const QString &id) const {
    return std::any_of(items.cbegin(), items.cend(), [&id](const QVariant &item) {
        return item.toMap().value("id").toString() == id;
    });
}
bool KWinWindowManagerBackend::rejectUnavailable() {
    emit requestRejected(tr("The window manager could not perform that action"));
    return false;
}
bool KWinWindowManagerBackend::request(const QString &operation, const QString &id,
                                       const QString &destination) {
    if (!m_ready || m_commands.size() >= 8)
        return rejectUnavailable();
    const auto name = "owode-command-" + QUuid::createUuid().toString(QUuid::Id128);
    const QJsonObject command{{"id", name},
                              {"operation", operation},
                              {"window", operation == "workspace" ? QString{} : id},
                              {"desktop", operation == "workspace" ? id : destination}};
    const auto source =
        scriptSource("kwin-command.js")
            .replace("@COMMAND@",
                     QString::fromUtf8(QJsonDocument(command).toJson(QJsonDocument::Compact)));
    m_commands.insert(name, name);
    loadScript(name, false, source.toUtf8());
    const auto generation = m_generation;
    QTimer::singleShot(5000, this, [this, generation, name] {
        if (generation == m_generation && m_commands.remove(name)) {
            unloadScript(m_owner, name);
            QFile::remove(m_scripts.filePath(name + ".js"));
            emit requestRejected(tr("The window manager could not perform that action"));
        }
    });
    return true; // Confirmed state arrives only through compositor snapshots.
}
void KWinWindowManagerBackend::commandFinished(const QString &token, const QString &id,
                                               bool accepted) {
    if (!trusted(token) || !m_commands.remove(id))
        return;
    unloadScript(m_owner, id);
    QFile::remove(m_scripts.filePath(id + ".js"));
    if (!accepted)
        emit requestRejected(tr("The window manager could not perform that action"));
}
bool KWinWindowManagerBackend::activateWorkspace(const QString &id) {
    return contains(m_workspaces, id) ? request("workspace", id) : rejectUnavailable();
}
bool KWinWindowManagerBackend::activateWindow(const QString &id) {
    return contains(m_windows, id) ? request("activate", id) : rejectUnavailable();
}
bool KWinWindowManagerBackend::closeWindow(const QString &id) {
    return contains(m_windows, id) ? request("close", id) : rejectUnavailable();
}
bool KWinWindowManagerBackend::moveWindow(const QString &id, const QString &workspaceId) {
    return contains(m_windows, id) && contains(m_workspaces, workspaceId)
               ? request("move", id, workspaceId)
               : rejectUnavailable();
}
bool KWinWindowManagerBackend::setWorkspaceLayout(const QString &, LayoutMode) {
    return rejectUnavailable();
}
bool KWinWindowManagerBackend::setWindowFloating(const QString &, bool) {
    return rejectUnavailable();
}
bool KWinWindowManagerBackend::applyWindowRule(const WindowRule &) { return rejectUnavailable(); }
} // namespace klde
