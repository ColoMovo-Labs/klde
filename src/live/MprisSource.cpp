// SPDX-License-Identifier: GPL-3.0-or-later
#include "MprisSource.h"
#include "mock/SystemStateModel.h"
#include <QDBusArgument>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <utility>

namespace {
const QString busService = QStringLiteral("org.freedesktop.DBus");
const QString prefix = QStringLiteral("org.mpris.MediaPlayer2.");
const QString playerPath = QStringLiteral("/org/mpris/MediaPlayer2");
const QString playerInterface = QStringLiteral("org.mpris.MediaPlayer2.Player");
const QString propertiesInterface = QStringLiteral("org.freedesktop.DBus.Properties");

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
    m_bus.connect(busService, QStringLiteral("/org/freedesktop/DBus"), busService,
                  QStringLiteral("NameOwnerChanged"), this,
                  SLOT(nameOwnerChanged(QString, QString, QString)));
    // Any sender: the unique owner is matched against the known players.
    m_bus.connect(QString(), playerPath, propertiesInterface, QStringLiteral("PropertiesChanged"),
                  this, SLOT(propertiesChanged(QDBusMessage)));
    auto *list =
        new QDBusPendingCallWatcher(m_bus.asyncCall(QDBusMessage::createMethodCall(
                                        busService, QStringLiteral("/org/freedesktop/DBus"),
                                        busService, QStringLiteral("ListNames"))),
                                    this);
    connect(list, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *self) {
        const QDBusPendingReply<QStringList> reply = *self;
        self->deleteLater();
        if (reply.isError())
            return;
        for (const auto &name : reply.value())
            if (name.startsWith(prefix))
                add(name);
    });
}

void MprisSource::nameOwnerChanged(const QString &name, const QString &oldOwner,
                                   const QString &newOwner) {
    if (!name.startsWith(prefix))
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
    auto owner = new QDBusPendingCallWatcher(
        m_bus.asyncCall(QDBusMessage::createMethodCall(busService,
                                                       QStringLiteral("/org/freedesktop/DBus"),
                                                       busService, QStringLiteral("GetNameOwner"))
                        << service),
        this);
    connect(owner, &QDBusPendingCallWatcher::finished, this,
            [this, service](QDBusPendingCallWatcher *self) {
                const QDBusPendingReply<QString> reply = *self;
                self->deleteLater();
                if (!reply.isError())
                    m_owners.insert(reply.value(), service);
            });
    auto message = QDBusMessage::createMethodCall(service, playerPath, propertiesInterface,
                                                  QStringLiteral("GetAll"));
    message << playerInterface;
    auto *properties = new QDBusPendingCallWatcher(m_bus.asyncCall(message), this);
    connect(properties, &QDBusPendingCallWatcher::finished, this,
            [this, service](QDBusPendingCallWatcher *self) {
                const QDBusPendingReply<QVariantMap> reply = *self;
                self->deleteLater();
                if (!reply.isError())
                    update(service, reply.value());
            });
}

void MprisSource::propertiesChanged(const QDBusMessage &message) {
    const auto service = m_owners.value(message.service());
    const auto arguments = message.arguments();
    if (service.isEmpty() || arguments.size() < 2 || arguments.at(0).toString() != playerInterface)
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
    auto *pending =
        new QDBusPendingCallWatcher(m_bus.asyncCall(QDBusMessage::createMethodCall(
                                        m_current, playerPath, playerInterface, method)),
                                    this);
    connect(pending, &QDBusPendingCallWatcher::finished, pending, &QObject::deleteLater);
    return true;
}
} // namespace klde
