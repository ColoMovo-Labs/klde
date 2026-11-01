// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QAbstractListModel>
#include <QDeadlineTimer>
#include <QImage>
#include <QTimer>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>
namespace klde {
class NotificationModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.notifications")
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int unreadCount READ unreadCount NOTIFY countChanged)
    Q_PROPERTY(bool native READ native NOTIFY serviceChanged)
    Q_PROPERTY(bool available READ available NOTIFY serviceChanged)
    Q_PROPERTY(QString serviceStatus READ serviceStatus NOTIFY serviceChanged)
    Q_PROPERTY(QVariantMap popup READ popup NOTIFY popupChanged)
    Q_PROPERTY(bool locked READ locked NOTIFY popupChanged)
  public:
    enum Role : quint16 {
        IdRole = Qt::UserRole + 1,
        SourceRole,
        TitleRole,
        BodyRole,
        SeverityRole,
        TitleTextRole,
        BodyTextRole,
        BodyMarkupRole,
        IconRole,
        ActionsRole,
        DemoRole,
        GroupStartRole
    };
    explicit NotificationModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = {}) const override {
        return parent.isValid() ? 0 : static_cast<int>(m_records.size());
    }
    int count() const { return rowCount(); }
    int unreadCount() const;
    bool native() const { return m_native; }
    bool available() const { return m_available; }
    QString serviceStatus() const { return m_serviceStatus; }
    bool locked() const { return m_locked; }
    QVariantMap popup() const;
    void setServiceState(bool available, const QString &status);
    void setDnd(bool enabled);
    void setLocked(bool locked);
    struct Incoming {
        QString sender, source, title, body, markup, appIcon;
        QVariantList actions;
        QImage image;
        int urgency = 1;
        int expireTimeout = -1;
        bool resident = false;
        bool transient = false;
    };
    uint receive(uint replacesId, const Incoming &notification);
    bool close(uint id, uint reason);
    QImage image(uint id, const QSize &size) const;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    void seedDemo(int count, const QString &context);
    Q_INVOKABLE bool dismiss(const QString &id);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void advancePopup();
    Q_INVOKABLE void pausePopup(bool paused);
    Q_INVOKABLE bool invokeAction(const QString &id, const QString &key);
    Q_INVOKABLE void markRead(const QString &id);
    Q_INVOKABLE void presentDemoPopup();
  signals:
    void countChanged();
    void serviceChanged();
    void popupChanged();
    void closed(uint id, uint reason);
    void actionInvoked(uint id, const QString &key);

  private:
    struct Record {
        QString id;
        QString source;
        QString titleId;
        QString bodyId;
        int severity = 0;
        Incoming incoming;
        bool demo = true;
        bool unread = true;
        uint revision = 0;
        QDeadlineTimer deadline{QDeadlineTimer::Forever};
    };
    QList<Record> m_records;
    bool m_native = false, m_available = false, m_dnd = false, m_locked = false;
    QString m_serviceStatus = QStringLiteral("mock");
    uint m_nextId = 0;
    QStringList m_pending;
    QString m_current;
    QTimer m_expiryTimer, m_popupTimer;
    bool m_paused = false;
    int m_popupRemaining = 4500;
    qint64 m_expiryRemaining = -1;
    void rescheduleExpiry();
    void enqueue(const QString &id);
    void stopPopups();
    QVariantMap presentation(const Record &record) const;
};
} // namespace klde
