// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "models/NotificationModel.h"
#include <QDBusConnection>
#include <QDBusContext>
#include <QDBusServiceWatcher>
#include <QQuickImageProvider>

namespace klde {
class NotificationServer final : public QObject, protected QDBusContext {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Notifications")
  public:
    explicit NotificationServer(NotificationModel *model,
                                const QDBusConnection &bus = QDBusConnection::sessionBus(),
                                QObject *parent = nullptr);
    ~NotificationServer() override;
    bool start();
  public slots:
    Q_SCRIPTABLE uint Notify(const QString &appName, uint replacesId, const QString &appIcon,
                             const QString &summary, const QString &body,
                             const QStringList &actions, const QVariantMap &hints,
                             int expireTimeout);
    Q_SCRIPTABLE void CloseNotification(uint id);
    Q_SCRIPTABLE QStringList GetCapabilities() const;
    Q_SCRIPTABLE QString GetServerInformation(QString &vendor, QString &version,
                                              QString &specVersion) const;
  signals:
    void NotificationClosed(uint id, uint reason);
    void ActionInvoked(uint id, const QString &actionKey);
    void ActivationToken(uint id, const QString &activationToken);
  private slots:
    void lockerActiveChanged(bool active);

  private:
    void queryLocker();
    NotificationModel *m_model;
    QDBusConnection m_bus;
    QDBusServiceWatcher m_lockerWatcher;
    bool m_owned = false;
    uint m_lockRevision = 0;
};
class NotificationIconProvider final : public QQuickImageProvider {
  public:
    explicit NotificationIconProvider(NotificationModel *model)
        : QQuickImageProvider(QQuickImageProvider::Image), m_model(model) {}
    QImage requestImage(const QString &id, QSize *size, const QSize &requested) override;

  private:
    NotificationModel *m_model;
};
} // namespace klde
