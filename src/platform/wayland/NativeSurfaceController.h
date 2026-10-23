// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class QWindow;

namespace klde {

// Applies the smallest LoMoDE-specific policy on top of LayerShellQt. The
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
    int attachedSurfaceCount() const { return m_attachedSurfaceCount; }
    QString diagnostic() const { return m_diagnostic; }

    // The object must be a QWindow that has not been shown yet. Calling this
    // before visible=true is important: LayerShellQt must configure the role
    // before the first Wayland surface commit.
    Q_INVOKABLE bool attach(QObject *object, const QString &role);
    Q_INVOKABLE bool supportsRole(const QString &role) const;

  signals:
    void changed();

  private:
    void setDiagnostic(const QString &diagnostic);

    int m_attachedSurfaceCount = 0;
    QString m_diagnostic;
};

} // namespace klde
