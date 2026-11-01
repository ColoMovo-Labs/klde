// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QDBusConnection>
#include <QDBusContext>
#include <QDBusServiceWatcher>
#include <QHash>
#include <QImage>
#include <QQuickImageProvider>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

namespace klde {
class StatusNotifierWatcher;
class StatusNotifierHost : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.tray")
    Q_PROPERTY(QVariantList items READ items NOTIFY changed)
    Q_PROPERTY(bool available READ available NOTIFY changed)
  public:
    explicit StatusNotifierHost(QObject *parent = nullptr);
    ~StatusNotifierHost() override;
    void start();
    bool available() const { return m_available; }
    QVariantList items() const;
    QImage image(const QString &id) const;
    Q_INVOKABLE void activate(const QString &id, int x, int y, bool secondary = false);
    Q_INVOKABLE void contextMenu(const QString &id, int x, int y);
    void registerItem(const QString &service, const QString &sender);
    QStringList registeredItems() const;
  signals:
    void changed();
    void itemStatusChanged();
    void requestRejected(const QString &message);
  private slots:
    void itemSignal(const QDBusMessage &message);
    void itemRegistered(const QString &id);
    void itemUnregistered(const QString &id);

  private:
    struct Item {
        QString id, service, path, owner, title, status;
        QImage icon;
        bool menu = false, pending = false, dirty = false;
        quint64 key = 0;
        int revision = 0;
    };
    void connectWatcher();
    void addItem(const QString &service, const QString &path, const QString &owner);
    void refreshItem(const QString &id);
    void removeItem(const QString &id);
    void invokeItem(const QString &id, const QVariantList &args, const QString &method);
    QDBusConnection m_bus;
    QDBusServiceWatcher m_ownerWatcher;
    StatusNotifierWatcher *m_protocol = nullptr;
    QHash<QString, Item> m_items;
    QStringList m_order;
    QString m_hostService;
    int m_generation = 0;
    quint64 m_nextKey = 1;
    bool m_available = false, m_started = false, m_ownsWatcher = false;
};
class TrayIconProvider final : public QQuickImageProvider {
  public:
    explicit TrayIconProvider(StatusNotifierHost *host)
        : QQuickImageProvider(QQuickImageProvider::Image), m_host(host) {}
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

  private:
    StatusNotifierHost *m_host;
};

// Only this small protocol object is exported, never the host's internal API.
class StatusNotifierWatcher final : public QObject, protected QDBusContext {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.StatusNotifierWatcher")
    Q_PROPERTY(QStringList RegisteredStatusNotifierItems READ registeredItems)
    Q_PROPERTY(bool IsStatusNotifierHostRegistered READ hostRegistered)
    Q_PROPERTY(int ProtocolVersion READ protocolVersion)
  public:
    explicit StatusNotifierWatcher(StatusNotifierHost *host) : QObject(host), m_host(host) {}
    QStringList registeredItems() const { return m_host->registeredItems(); }
    bool hostRegistered() const { return true; }
    int protocolVersion() const { return 0; }
  public slots:
    Q_SCRIPTABLE void RegisterStatusNotifierItem(const QString &service);
    Q_SCRIPTABLE void RegisterStatusNotifierHost(const QString &service);
  signals:
    Q_SCRIPTABLE void StatusNotifierItemRegistered(const QString &service);
    Q_SCRIPTABLE void StatusNotifierItemUnregistered(const QString &service);
    Q_SCRIPTABLE void StatusNotifierHostRegistered();
    Q_SCRIPTABLE void StatusNotifierHostUnregistered();

  private:
    StatusNotifierHost *m_host;
};
} // namespace klde
