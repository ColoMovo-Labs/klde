// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "WindowManagerBackend.h"

namespace klde {
class MockWindowManagerBackend final : public WindowManagerBackend {
    Q_OBJECT
  public:
    explicit MockWindowManagerBackend(QObject *parent = nullptr);
    QVariantList workspaces() const override;
    QVariantList windows() const override;
    QString activeWorkspace() const override;
    QVariantMap capabilities() const override;
    bool activateWorkspace(const QString &id) override;
    bool setWorkspaceLayout(const QString &id, LayoutMode mode) override;
    bool setWindowFloating(const QString &id, bool floating) override;
    bool moveWindow(const QString &id, const QString &workspaceId) override;
    bool applyWindowRule(const WindowRule &rule) override;

  private:
    bool hasWorkspace(const QString &id) const;
    bool reject(const QString &reason);
    QVariantList m_workspaces;
    QVariantList m_windows;
    QString m_activeWorkspace = QStringLiteral("workspace-1");
};
} // namespace klde
