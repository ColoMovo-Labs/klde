// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QHash>
#include <QObject>
#include <QSet>
#include <QString>
#include <QtQml/qqmlregistration.h>

class QWindow;
class QQuickItem;

namespace klde {

// Applies the smallest owoDE-specific policy on top of LayerShellQt. The
// controller is deliberately optional: the ordinary preview and Visual Lab do
// not require a compositor-provided layer-shell protocol.
class NativeSurfaceController : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.surface")
    Q_PROPERTY(bool compiledIn READ compiledIn CONSTANT)
    Q_PROPERTY(bool wayland READ wayland CONSTANT)
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(int attachedSurfaceCount READ attachedSurfaceCount NOTIFY changed)
    Q_PROPERTY(QString diagnostic READ diagnostic NOTIFY changed)

  public:
    explicit NativeSurfaceController(QObject *parent = nullptr);

    bool compiledIn() const;
    bool wayland() const;
    bool available() const;
    int attachedSurfaceCount() const { return static_cast<int>(m_roles.size()); }
    QString diagnostic() const { return m_diagnostic; }

    // The object must be a QWindow that has not been shown yet. Calling this
    // before visible=true is important: LayerShellQt must configure the role
    // before the first Wayland surface commit.
    Q_INVOKABLE bool attach(QObject *object, const QString &role);
    Q_INVOKABLE bool supportsRole(const QString &role) const;
    Q_INVOKABLE bool hasRole(const QString &role) const;
    // Space reserved from the edge an attached ribbon or dock is anchored to.
    // 0 lets windows extend underneath; the value is clamped to the surface.
    Q_INVOKABLE bool setExclusiveZone(QObject *object, int zone);
    Q_INVOKABLE int exclusiveZone(QObject *object) const;
    // Retargets a hidden surface to the named output; an empty name lets the
    // compositor pick its active output. Takes effect when the window is shown.
    Q_INVOKABLE bool setOutput(QObject *object, const QString &screenName);

  signals:
    void changed();

  private:
    void setDiagnostic(const QString &diagnostic);
    void observeInputTree(QQuickItem *item, QWindow *window);
    void queueInputRegion(QWindow *window);
    void updateInputRegion(QWindow *window);

    QHash<QWindow *, QString> m_roles;
    QHash<QWindow *, int> m_zones;
    QSet<QQuickItem *> m_observedItems;
    QSet<QWindow *> m_pendingRegions;
    QString m_diagnostic;
};

} // namespace klde
