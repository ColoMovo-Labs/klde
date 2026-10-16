// SPDX-License-Identifier: GPL-3.0-or-later
#include "MockWindowManagerBackend.h"

#include <algorithm>

namespace klde {
MockWindowManagerBackend::MockWindowManagerBackend(QObject *parent) : WindowManagerBackend(parent) {
    const QList<LayoutMode> modes{Floating, Floating, Tiled, Mixed, Custom};
    for (int i = 0; i < modes.size(); ++i) {
        m_workspaces.append(QVariantMap{{"id", QStringLiteral("workspace-%1").arg(i + 1)},
                                        {"name", QString::number(i + 1)},
                                        {"layout", static_cast<int>(modes.at(i))}});
    }
    m_windows.append(QVariantMap{{"id", "demo-terminal"},
                                 {"applicationId", "terminal"},
                                 {"workspaceId", "workspace-1"},
                                 {"floating", true}});
}

QVariantList MockWindowManagerBackend::workspaces() const { return m_workspaces; }
QVariantList MockWindowManagerBackend::windows() const { return m_windows; }
QString MockWindowManagerBackend::activeWorkspace() const { return m_activeWorkspace; }
QVariantMap MockWindowManagerBackend::capabilities() const {
    return {{"mock", true},         {"workspaceLayouts", true},  {"perWindowFloating", true},
            {"windowRules", false}, {"rememberGeometry", false}, {"scrollingTiling", false}};
}

bool MockWindowManagerBackend::hasWorkspace(const QString &id) const {
    return std::any_of(m_workspaces.cbegin(), m_workspaces.cend(), [&id](const QVariant &item) {
        return item.toMap().value("id").toString() == id;
    });
}

bool MockWindowManagerBackend::reject(const QString &reason) {
    emit requestRejected(reason);
    return false;
}

bool MockWindowManagerBackend::activateWorkspace(const QString &id) {
    if (!hasWorkspace(id)) {
        return reject(QStringLiteral("Unknown workspace"));
    }
    if (m_activeWorkspace != id) {
        m_activeWorkspace = id;
        emit activeWorkspaceChanged();
    }
    return true;
}

bool MockWindowManagerBackend::setWorkspaceLayout(const QString &id, LayoutMode mode) {
    if (mode < Floating || mode > Custom || mode == Scrolling) {
        return reject(QStringLiteral("Layout unsupported by mock backend"));
    }
    for (auto &entry : m_workspaces) {
        auto workspace = entry.toMap();
        if (workspace.value("id").toString() == id) {
            if (workspace.value("layout").toInt() != mode) {
                workspace["layout"] = static_cast<int>(mode);
                entry = workspace;
                emit workspacesChanged();
            }
            return true;
        }
    }
    return reject(QStringLiteral("Unknown workspace"));
}

bool MockWindowManagerBackend::setWindowFloating(const QString &id, bool floating) {
    for (auto &entry : m_windows) {
        auto window = entry.toMap();
        if (window.value("id").toString() == id) {
            if (window.value("floating").toBool() != floating) {
                window["floating"] = floating;
                entry = window;
                emit windowsChanged();
            }
            return true;
        }
    }
    return reject(QStringLiteral("Unknown window"));
}

bool MockWindowManagerBackend::moveWindow(const QString &id, const QString &workspaceId) {
    if (!hasWorkspace(workspaceId)) {
        return reject(QStringLiteral("Unknown destination workspace"));
    }
    for (auto &entry : m_windows) {
        auto window = entry.toMap();
        if (window.value("id").toString() == id) {
            if (window.value("workspaceId").toString() != workspaceId) {
                window["workspaceId"] = workspaceId;
                entry = window;
                emit windowsChanged();
            }
            return true;
        }
    }
    return reject(QStringLiteral("Unknown window"));
}

bool MockWindowManagerBackend::applyWindowRule(const WindowRule &) {
    return reject(QStringLiteral("Persistent application rules are a future adapter capability"));
}
} // namespace klde
