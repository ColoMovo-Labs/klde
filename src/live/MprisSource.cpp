// SPDX-License-Identifier: GPL-3.0-or-later
#include "MprisSource.h"
#include "mock/SystemStateModel.h"
#include <QDBusArgument>
#include <QDBusPendingCallWatcher>
#include <QTimer>
#include <algorithm>
#include <utility>

namespace {
const QString &busService() {
    static const QString value = QStringLiteral("org.freedesktop.DBus");
    return value;
}
const QString &prefix() {
    static const QString value = QStringLiteral("org.mpris.MediaPlayer2.");
    return value;
}
const QString &playerPath() {
    static const QString value = QStringLiteral("/org/mpris/MediaPlayer2");
    return value;
}
const QString &playerInterface() {
    static const QString value = QStringLiteral("org.mpris.MediaPlayer2.Player");
    return value;
}
const QString &propertiesInterface() {
    static const QString value = QStringLiteral("org.freedesktop.DBus.Properties");
    return value;
}

QVariantMap asMap(const QVariant &value) {
    if (value.canConvert<QDBusArgument>())
        return qdbus_cast<QVariantMap>(value.value<QDBusArgument>());
    return value.toMap();
}

QString bounded(const QString &raw) {
    QString result;
    for (const QChar c : raw) {
        if (c.isPrint())
            result.append(c);
        if (result.size() >= 120)
            break;
    }
    return result.trimmed();
}
} // namespace

namespace klde {
MprisSource::MprisSource(SystemStateModel *state, QDBusConnection bus, QObject *parent)
    : QObject(parent), m_state(state), m_bus(std::move(bus)) {}

QString MprisSource::title(const QVariant &metadata) {
    return bounded(asMap(metadata).value(QStringLiteral("xesam:title")).toString());
}

QString MprisSource::artist(const QVariant &metadata) {
    const auto value = asMap(metadata).value(QStringLiteral("xesam:artist"));
    const QStringList artists = value.canConvert<QDBusArgument>()
                                    ? qdbus_cast<QStringList>(value.value<QDBusArgument>())
                                    : value.toStringList();
    return bounded(artists.join(QStringLiteral(", ")));
}

void MprisSource::start() {
    m_state->publishLive(QStringLiteral("media.available"), false);
    m_state->publishLive(QStringLiteral("media.playing"), false);
    m_state->publishLive(QStringLiteral("media.title"), QString());
    m_state->publishLive(QStringLiteral("media.artist"), QString());
    m_state->setLiveWriter(QStringLiteral("media.playing"), [this](const QVariant &value) {
        return call(value.toBool() ? QStringLiteral("Play") : QStringLiteral("Pause"));
    });
    m_bus.connect(busService(), QStringLiteral("/org/freedesktop/DBus"), busService(),
                  QStringLiteral("NameOwnerChanged"), this,
                  SLOT(nameOwnerChanged(QString, QString, QString)));
    // Any sender: the unique owner is matched against the known players.
    m_bus.connect(QString(), playerPath(), propertiesInterface(),
                  QStringLiteral("PropertiesChanged"), this, SLOT(propertiesChanged(QDBusMessage)));
    invoke(QDBusMessage::createMethodCall(busService(), QStringLiteral("/org/freedesktop/DBus"),
                                          busService(), QStringLiteral("ListNames")),
           [this](const QDBusMessage &reply) {
               if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty())
                   return;
               for (const auto &name : reply.arguments().constFirst().toStringList())
                   if (name.startsWith(prefix()))
                       add(name);
           });
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): D-Bus signal order.
void MprisSource::nameOwnerChanged(const QString &name, const QString &oldOwner,
                                   const QString &newOwner) {
    if (!name.startsWith(prefix()))
        return;
    if (!oldOwner.isEmpty()) {
        m_players.remove(name);
        m_owners.remove(oldOwner);
    }
    if (!newOwner.isEmpty())
        add(name);
    else
        publish();
}

void MprisSource::add(const QString &service) {
    m_players.insert(service, Player{});
    invoke(QDBusMessage::createMethodCall(busService(), QStringLiteral("/org/freedesktop/DBus"),
                                          busService(), QStringLiteral("GetNameOwner"))
               << service,
           [this, service](const QDBusMessage &reply) {
               if (reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty())
                   m_owners.insert(reply.arguments().constFirst().toString(), service);
           });
    auto message = QDBusMessage::createMethodCall(service, playerPath(), propertiesInterface(),
                                                  QStringLiteral("GetAll"));
    message << playerInterface();
    invoke(message, [this, service](const QDBusMessage &reply) {
        if (reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty())
            update(service, asMap(reply.arguments().constFirst()));
    });
}

void MprisSource::propertiesChanged(const QDBusMessage &message) {
    const auto service = m_owners.value(message.service());
    const auto arguments = message.arguments();
    if (service.isEmpty() || arguments.size() < 2 ||
        arguments.at(0).toString() != playerInterface())
        return;
    update(service, asMap(arguments.at(1)));
}

void MprisSource::update(const QString &service, const QVariantMap &changed) {
    auto it = m_players.find(service);
    if (it == m_players.end())
        return;
    if (changed.contains(QStringLiteral("PlaybackStatus"))) {
        const auto status = changed.value(QStringLiteral("PlaybackStatus")).toString();
        if (status == QLatin1String("Playing") && it->status != status)
            it->playingSince = ++m_sequence;
        it->status = status;
    }
    if (changed.contains(QStringLiteral("Metadata")))
        it->metadata = changed.value(QStringLiteral("Metadata"));
    publish();
}

void MprisSource::publish() {
    // Most recently started player that is playing, else the most recent one.
    QString chosen;
    quint64 best = 0;
    bool playing = false;
    for (auto it = m_players.cbegin(); it != m_players.cend(); ++it) {
        const bool isPlaying = it->status == QLatin1String("Playing");
        if (chosen.isEmpty() || (isPlaying && !playing) ||
            (isPlaying == playing && it->playingSince > best)) {
            chosen = it.key();
            best = it->playingSince;
            playing = isPlaying;
        }
    }
    m_current = chosen;
    const auto player = m_players.value(chosen);
    m_state->publishLive(QStringLiteral("media.available"), !chosen.isEmpty());
    m_state->publishLive(QStringLiteral("media.playing"), playing);
    m_state->publishLive(QStringLiteral("media.title"), title(player.metadata));
    m_state->publishLive(QStringLiteral("media.artist"), artist(player.metadata));
}

bool MprisSource::call(const QString &method) {
    if (m_current.isEmpty())
        return false;
    invoke(QDBusMessage::createMethodCall(m_current, playerPath(), playerInterface(), method),
           [](const QDBusMessage &) {});
    return true;
}

void MprisSource::invoke(const QDBusMessage &message,
                         std::function<void(const QDBusMessage &)> handler) {
    auto pending = std::make_unique<QDBusPendingCallWatcher>(m_bus.asyncCall(message));
    auto *watcher = pending.get();
    m_pending.push_back(std::move(pending));
    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, handler = std::move(handler)](QDBusPendingCallWatcher *finished) {
                const auto reply = finished->reply();
                QTimer::singleShot(0, this, [this, finished] {
                    std::erase_if(m_pending, [finished](const auto &entry) {
                        return entry.get() == finished;
                    });
                });
                handler(reply);
            });
}
} // namespace klde
