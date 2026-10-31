// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QRect>
#include <QRectF>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>
#include <algorithm>

namespace klde {

// Stable, opaque IDs belong to a backend. Never pass native compositor handles to QML.
struct WindowRule {
    QString applicationId;
    QString workspaceId;
    bool floating = true;
    QRect rememberedGeometry;
};

class WindowManagerBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.windowManager")
    Q_PROPERTY(QVariantList workspaces READ workspaces NOTIFY workspacesChanged)
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)
    Q_PROPERTY(QString activeWorkspace READ activeWorkspace NOTIFY activeWorkspaceChanged)
    Q_PROPERTY(QVariantMap capabilities READ capabilities NOTIFY capabilitiesChanged)
    Q_PROPERTY(int pendingRequests READ pendingRequests NOTIFY pendingRequestsChanged)

  public:
    // Keep the numeric layout IDs stable while exposing the neutral product name.
    enum LayoutMode : quint8 {
        Floating,
        ClassicTiling,
        Mixed,
        Scrolling,
        Custom,
        Tiled = ClassicTiling // source/config compatibility for the earlier mock API
    };
    Q_ENUM(LayoutMode)
    using QObject::QObject;
    virtual QVariantList workspaces() const = 0;
    virtual QVariantList windows() const = 0;
    virtual QString activeWorkspace() const = 0;
    virtual QVariantMap capabilities() const = 0;
    virtual int pendingRequests() const { return 0; }

    // true means accepted; observers use change signals for confirmed state.
    Q_INVOKABLE virtual bool activateWorkspace(const QString &id) = 0;
    Q_INVOKABLE virtual bool setWorkspaceLayout(const QString &id, LayoutMode mode) = 0;
    Q_INVOKABLE virtual bool setWindowFloating(const QString &id, bool floating) = 0;
    Q_INVOKABLE virtual bool moveWindow(const QString &id, const QString &workspaceId) = 0;
    Q_INVOKABLE virtual bool activateWindow(const QString &) { return false; }
    Q_INVOKABLE virtual bool closeWindow(const QString &) { return false; }
    virtual bool applyWindowRule(const WindowRule &rule) = 0;

    // True when a visible window on the active workspace intersects area, in
    // compositor-global logical coordinates. Windows without known geometry
    // never count, so mock backends keep a smart-hiding dock visible.
    Q_INVOKABLE bool windowOverlaps(const QRectF &area) const {
        const auto active = activeWorkspace();
        const auto items = windows();
        return std::any_of(items.cbegin(), items.cend(), [&](const QVariant &item) {
            const auto window = item.toMap();
            const auto geometry = window.value(QStringLiteral("geometry"));
            if (!geometry.isValid() || window.value(QStringLiteral("minimized")).toBool())
                return false;
            const bool here =
                window.value(QStringLiteral("onAllWorkspaces")).toBool() ||
                window.value(QStringLiteral("workspaceId")).toString() == active ||
                window.value(QStringLiteral("workspaceIds")).toStringList().contains(active);
            return here && geometry.toRectF().intersects(area);
        });
    }

  signals:
    void workspacesChanged();
    void windowsChanged();
    void activeWorkspaceChanged();
    void capabilitiesChanged();
    void pendingRequestsChanged();
    void requestRejected(const QString &reason);
};

} // namespace klde
