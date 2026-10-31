// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QHash>
#include <QObject>
#include <QString>
#include <QVariantMap>
#include <functional>
#include <memory>
#include <vector>

namespace klde {
class SystemStateModel;

// Follows MPRIS media players on the session bus. The player that most
// recently started playing is shown; title and artist are untrusted text.
class MprisSource final : public QObject {
    Q_OBJECT
  public:
    explicit MprisSource(SystemStateModel *state,
                         QDBusConnection bus = QDBusConnection::sessionBus(),
                         QObject *parent = nullptr);
    void start();
    bool previous() { return call(QStringLiteral("Previous")); }
    bool next() { return call(QStringLiteral("Next")); }
    // Metadata's xesam:title and xesam:artist, bounded printable text.
    static QString title(const QVariant &metadata);
    static QString artist(const QVariant &metadata);

  private slots:
    // The D-Bus NameOwnerChanged signature fixes this parameter order.
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
    void nameOwnerChanged(const QString &name, const QString &oldOwner, const QString &newOwner);
    void propertiesChanged(const QDBusMessage &message);

  private:
    struct Player {
        QString status;
        QVariant metadata;
        quint64 playingSince = 0;
    };
    void add(const QString &service);
    void update(const QString &service, const QVariantMap &changed);
    void publish();
    bool call(const QString &method);
    // Owns each pending call until its reply has been handled.
    void invoke(const QDBusMessage &message, std::function<void(const QDBusMessage &)> handler);
    std::vector<std::unique_ptr<QDBusPendingCallWatcher>> m_pending;
    SystemStateModel *m_state;
    QDBusConnection m_bus;
    QHash<QString, Player> m_players;
    QHash<QString, QString> m_owners;
    QString m_current;
    quint64 m_sequence = 0;
};
} // namespace klde
