// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

namespace klde {

// Read-only runtime capability probe. It never starts a compositor, changes the
// host session or claims that a mock surface is a desktop shell surface.
class SessionRuntimeBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.session")
    Q_PROPERTY(bool waylandSession READ waylandSession NOTIFY changed)
    Q_PROPERTY(bool kwinService READ kwinService NOTIFY changed)
    Q_PROPERTY(bool kwinDetected READ kwinDetected NOTIFY changed)
    Q_PROPERTY(bool layerShellAvailable READ layerShellAvailable NOTIFY changed)
    Q_PROPERTY(QString waylandDisplay READ waylandDisplay NOTIFY changed)
    Q_PROPERTY(QString compositor READ compositor NOTIFY changed)
    Q_PROPERTY(QString diagnostic READ diagnostic NOTIFY changed)
    Q_PROPERTY(QVariantMap capabilities READ capabilities NOTIFY changed)

  public:
    explicit SessionRuntimeBackend(QObject *parent = nullptr);

    bool waylandSession() const { return m_waylandSession; }
    bool kwinService() const { return m_kwinService; }
    bool kwinDetected() const { return m_kwinDetected; }
    bool layerShellAvailable() const { return m_layerShellAvailable; }
    QString waylandDisplay() const { return m_waylandDisplay; }
    QString compositor() const { return m_compositor; }
    QString diagnostic() const { return m_diagnostic; }
    QVariantMap capabilities() const;

    // Re-probe on demand after an isolated session has been started. This is
    // intentionally event-driven; the shell must not poll the session bus.
    Q_INVOKABLE bool refresh();

  signals:
    void changed();

  private:
    bool m_waylandSession = false;
    bool m_kwinService = false;
    bool m_kwinDetected = false;
    bool m_layerShellAvailable = false;
    QString m_waylandDisplay;
    QString m_compositor;
    QString m_diagnostic;
};

} // namespace klde
