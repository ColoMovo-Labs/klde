// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "WindowManagerBackend.h"
#include <QDBusContext>
#include <QDBusServiceWatcher>
#include <QHash>
#include <QTemporaryDir>
#include <QTimer>

namespace klde {
// A session-scoped, event-driven adapter. No KWin private C++ ABI is linked.
class KWinWindowManagerBackend final : public WindowManagerBackend, protected QDBusContext {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.owode.KWinBridge1")
  public:
    explicit KWinWindowManagerBackend(QObject *parent = nullptr);
    ~KWinWindowManagerBackend() override;
    void start();
    QVariantList workspaces() const override { return m_workspaces; }
    QVariantList windows() const override { return m_windows; }
    QString activeWorkspace() const override { return m_activeWorkspace; }
    QVariantMap capabilities() const override;
    bool activateWorkspace(const QString &id) override;
    bool activateWindow(const QString &id) override;
    bool closeWindow(const QString &id) override;
    bool moveWindow(const QString &id, const QString &workspaceId) override;
    bool setWorkspaceLayout(const QString &, LayoutMode) override;
    bool setWindowFloating(const QString &, bool) override;
    bool applyWindowRule(const WindowRule &) override;

  public slots:
    Q_SCRIPTABLE bool snapshot(const QString &token, const QString &json);
    Q_SCRIPTABLE void commandFinished(const QString &token, const QString &id, bool accepted);

  private:
    void ownerChanged(const QString &owner);
    void clearState(const QString &diagnostic);
    QString scriptSource(const QString &file) const;
    void loadScript(const QString &name, bool reporter, const QByteArray &source);
    void unloadScript(const QString &owner, const QString &name);
    bool trusted(const QString &token) const;
    bool request(const QString &operation, const QString &id, const QString &destination = {});
    bool rejectUnavailable();
    bool contains(const QVariantList &items, const QString &id) const;

    QDBusServiceWatcher m_watcher;
    QTemporaryDir m_scripts;
    QTimer m_deadline;
    QString m_owner;
    QString m_token;
    QString m_objectPath;
    QString m_reporter;
    QString m_version;
    QString m_diagnostic;
    QHash<QString, QString> m_commands;
    QVariantList m_workspaces;
    QVariantList m_windows;
    QString m_activeWorkspace;
    quint64 m_generation = 0;
    qint64 m_sequence = 0;
    bool m_started = false;
    bool m_registered = false;
    bool m_ready = false;
};
} // namespace klde
