// SPDX-License-Identifier: GPL-3.0-or-later
#include "StatusNotifierHost.h"
#include <QDBusArgument>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QIcon>
#include <QPainter>
#include <QRegularExpression>
#include <QUuid>
#include <QtEndian>
#include <algorithm>
#include <utility>

namespace {
constexpr auto watcherName = "org.kde.StatusNotifierWatcher";
constexpr auto watcherPath = "/StatusNotifierWatcher";
constexpr auto itemInterface = "org.kde.StatusNotifierItem";
QImage decodePixmap(const QVariant &value) {
    if (value.metaType() != QMetaType::fromType<QDBusArgument>())
        return {};
    const auto array = qvariant_cast<QDBusArgument>(value);
    if (array.currentSignature() != "a(iiay)")
        return {};
    QImage best;
    array.beginArray();
    while (!array.atEnd()) {
        int width = 0, height = 0;
        QByteArray bytes;
        array.beginStructure();
        array >> width >> height >> bytes;
        array.endStructure();
        if (width <= 0 || height <= 0 || width > 512 || height > 512 ||
            bytes.size() != static_cast<qint64>(width) * height * 4 ||
            (!best.isNull() && width <= best.width()))
            continue;
        QImage image(width, height, QImage::Format_ARGB32);
        for (int y = 0; y < height; ++y) {
            auto *line = reinterpret_cast<QRgb *>(image.scanLine(y));
            for (int x = 0; x < width; ++x)
                line[x] =
                    qFromBigEndian<quint32>(bytes.constData() + (qsizetype{y} * width + x) * 4);
        }
        best = image.scaled(64, 64, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    array.endArray();
    return best;
}
} // namespace
namespace klde {
StatusNotifierHost::StatusNotifierHost(QObject *parent)
    : QObject(parent), m_bus(QDBusConnection::sessionBus()), m_ownerWatcher(this) {}
StatusNotifierHost::~StatusNotifierHost() {
    if (m_ownsWatcher) {
        m_bus.unregisterObject(watcherPath);
        m_bus.unregisterService(watcherName);
    }
    if (!m_hostService.isEmpty())
        m_bus.unregisterService(m_hostService);
}
void StatusNotifierHost::start() {
    if (m_started || !m_bus.isConnected())
        return;
    m_started = true;
    m_hostService = QStringLiteral("org.kde.StatusNotifierHost-owoDE-") +
                    QUuid::createUuid().toString(QUuid::Id128);
    if (!m_bus.registerService(m_hostService)) {
        m_hostService.clear();
        return;
    }
    m_ownerWatcher.setConnection(m_bus);
    m_ownerWatcher.setWatchMode(QDBusServiceWatcher::WatchForOwnerChange);
    m_ownerWatcher.addWatchedService(watcherName);
    connect(&m_ownerWatcher, &QDBusServiceWatcher::serviceOwnerChanged, this,
            [this](const QString &name, const QString &oldOwner, const QString &newOwner) {
                if (name == watcherName && !m_ownsWatcher) {
                    connectWatcher();
                    return;
                }
                if (oldOwner.isEmpty() || oldOwner == newOwner)
                    return;
                const auto ids = m_order;
                for (const auto &id : ids)
                    if ((name == oldOwner && m_items.value(id).owner == oldOwner) ||
                        m_items.value(id).service == name)
                        removeItem(id);
            });
    connectWatcher();
}
void StatusNotifierHost::connectWatcher() {
    ++m_generation;
    const auto previous = m_order;
    for (const auto &id : previous)
        removeItem(id);
    const auto owner = m_bus.interface()->serviceOwner(watcherName);
    if (!owner.isValid() || owner.value().isEmpty()) {
        if (!m_protocol)
            m_protocol = new StatusNotifierWatcher(this);
        if (m_bus.registerService(watcherName)) {
            if (m_bus.registerObject(watcherPath, m_protocol,
                                     QDBusConnection::ExportScriptableSlots |
                                         QDBusConnection::ExportScriptableSignals |
                                         QDBusConnection::ExportAllProperties)) {
                m_ownsWatcher = true;
                m_available = true;
                emit changed();
                return;
            }
            m_bus.unregisterService(watcherName);
        }
    }
    if (m_ownsWatcher)
        return;
    m_available = false;
    emit changed();
    m_bus.disconnect(watcherName, watcherPath, watcherName, QString(), this, nullptr);
    m_bus.connect(watcherName, watcherPath, watcherName, "StatusNotifierItemRegistered", this,
                  SLOT(itemRegistered(QString)));
    m_bus.connect(watcherName, watcherPath, watcherName, "StatusNotifierItemUnregistered", this,
                  SLOT(itemUnregistered(QString)));
    auto request = QDBusMessage::createMethodCall(watcherName, watcherPath,
                                                  "org.freedesktop.DBus.Properties", "GetAll");
    request.setArguments({watcherName});
    auto *pending = new QDBusPendingCallWatcher(m_bus.asyncCall(request, 2000), this);
    const auto generation = m_generation;
    connect(pending, &QDBusPendingCallWatcher::finished, this,
            [this, generation](QDBusPendingCallWatcher *call) {
                const QDBusPendingReply<QVariantMap> reply = *call;
                call->deleteLater();
                if (generation != m_generation || reply.isError())
                    return;
                m_available = true;
                const auto ids =
                    qdbus_cast<QStringList>(reply.value().value("RegisteredStatusNotifierItems"));
                for (const auto &id : ids.mid(0, 64))
                    itemRegistered(id);
                auto registration = QDBusMessage::createMethodCall(
                    watcherName, watcherPath, watcherName, "RegisterStatusNotifierHost");
                registration.setArguments({m_hostService});
                m_bus.asyncCall(registration, 2000);
                emit changed();
            });
}
void StatusNotifierWatcher::RegisterStatusNotifierItem(const QString &service) {
    if (calledFromDBus())
        m_host->registerItem(service, message().service());
}
void StatusNotifierWatcher::RegisterStatusNotifierHost(const QString &service) {
    if (!calledFromDBus() || service.isEmpty())
        return;
    const auto owner = connection().interface()->serviceOwner(service);
    if (owner.isValid() && owner.value() == message().service())
        emit StatusNotifierHostRegistered();
}
void StatusNotifierHost::registerItem(const QString &service, const QString &sender) {
    if (service.isEmpty() || service.size() > 512 || sender.isEmpty())
        return;
    if (service.startsWith('/')) {
        static const QRegularExpression path(
            QStringLiteral("^/(?:[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*)?$"));
        if (path.match(service).hasMatch())
            addItem(sender, service, sender);
        return;
    }
    const auto owner = m_bus.interface()->serviceOwner(service);
    if (owner.isValid() && owner.value() == sender)
        addItem(service, QStringLiteral("/StatusNotifierItem"), sender);
}
void StatusNotifierHost::itemRegistered(const QString &id) {
    const auto slash = id.indexOf('/');
    if (slash <= 0 || id.size() > 1024)
        return;
    const auto service = id.left(slash);
    const auto owner = m_bus.interface()->serviceOwner(service);
    if (owner.isValid())
        addItem(service, id.mid(slash), owner.value());
}
void StatusNotifierHost::itemUnregistered(const QString &id) { removeItem(id); }
void StatusNotifierHost::addItem(const QString &service, const QString &path,
                                 const QString &owner) {
    const auto id = service + path;
    const bool duplicate =
        std::any_of(m_items.cbegin(), m_items.cend(), [&owner, &path](const auto &item) {
            return item.owner == owner && item.path == path;
        });
    if (duplicate || m_order.size() >= 64 || owner.isEmpty())
        return;
    Item item;
    item.id = id;
    item.service = service;
    item.path = path;
    item.owner = owner;
    m_items.insert(id, std::move(item));
    m_items[id].key = m_nextKey++;
    m_order.append(id);
    m_ownerWatcher.addWatchedService(owner);
    m_ownerWatcher.addWatchedService(service);
    for (const auto *signal :
         {"NewIcon", "NewAttentionIcon", "NewToolTip", "NewTitle", "NewStatus"})
        m_bus.connect(service, path, itemInterface, QString::fromLatin1(signal), this,
                      SLOT(itemSignal(QDBusMessage)));
    refreshItem(id);
    if (m_ownsWatcher)
        emit m_protocol->StatusNotifierItemRegistered(id);
}
void StatusNotifierHost::removeItem(const QString &id) {
    if (!m_items.contains(id))
        return;
    const auto item = m_items.take(id);
    m_order.removeAll(id);
    m_bus.disconnect(item.service, item.path, itemInterface, QString(), this, nullptr);
    const bool ownerStillUsed =
        std::any_of(m_items.cbegin(), m_items.cend(),
                    [&item](const auto &other) { return other.owner == item.owner; });
    if (!ownerStillUsed)
        m_ownerWatcher.removeWatchedService(item.owner);
    const bool serviceStillUsed =
        std::any_of(m_items.cbegin(), m_items.cend(),
                    [&item](const auto &other) { return other.service == item.service; });
    if (!serviceStillUsed)
        m_ownerWatcher.removeWatchedService(item.service);
    if (m_ownsWatcher)
        emit m_protocol->StatusNotifierItemUnregistered(id);
    emit changed();
}
void StatusNotifierHost::itemSignal(const QDBusMessage &message) {
    for (const auto &id : m_order) {
        const auto &item = m_items[id];
        if (item.owner == message.service() && item.path == message.path()) {
            const auto applicationId = item.applicationId;
            refreshItem(id);
            emit itemStatusChanged(applicationId);
        }
    }
}
void StatusNotifierHost::refreshItem(const QString &id) {
    auto found = m_items.find(id);
    if (found == m_items.end())
        return;
    if (found->pending) {
        found->dirty = true;
        return;
    }
    found->pending = true;
    auto message = QDBusMessage::createMethodCall(found->owner, found->path,
                                                  "org.freedesktop.DBus.Properties", "GetAll");
    message.setArguments({itemInterface});
    const auto owner = found->owner;
    const auto key = found->key;
    auto *pending = new QDBusPendingCallWatcher(m_bus.asyncCall(message, 2000), this);
    connect(pending, &QDBusPendingCallWatcher::finished, this,
            [this, id, owner, key](QDBusPendingCallWatcher *call) {
                const QDBusPendingReply<QVariantMap> reply = *call;
                call->deleteLater();
                auto found = m_items.find(id);
                if (found == m_items.end() || found->owner != owner || found->key != key)
                    return;
                found->pending = false;
                if (std::exchange(found->dirty, false))
                    QTimer::singleShot(50, this, [this, id] { refreshItem(id); });
                if (reply.isError())
                    return;
                const auto fields = reply.value();
                found->applicationId = fields.value("Id").toString().left(128);
                found->title = fields.value("Title").toString().left(128);
                if (found->title.isEmpty())
                    found->title = fields.value("Id").toString().left(128);
                found->status = fields.value("Status").toString();
                found->menu = fields.value("ItemIsMenu").toBool();
                const auto iconField =
                    found->status == "NeedsAttention" ? "AttentionIconName" : "IconName";
                const auto pixmapField =
                    found->status == "NeedsAttention" ? "AttentionIconPixmap" : "IconPixmap";
                const auto iconName = fields.value(iconField).toString().left(512);
                found->icon = QIcon::fromTheme(iconName).pixmap(32, 32).toImage();
                if (found->icon.isNull() && fields.contains(pixmapField))
                    found->icon = decodePixmap(fields.value(pixmapField));
                ++found->revision;
                emit changed();
            });
}
QStringList StatusNotifierHost::registeredItems() const { return m_order; }
QVariantList StatusNotifierHost::items() const {
    QVariantList result;
    for (const auto &id : m_order) {
        const auto item = m_items.value(id);
        if (item.status.isEmpty() || item.status == "Passive")
            continue;
        result.append(QVariantMap{{"id", id},
                                  {"title", item.title},
                                  {"icon", "image://tray/" + QString::number(item.key) + "/" +
                                               QString::number(item.revision)},
                                  {"attention", item.status == "NeedsAttention"}});
    }
    return result;
}
QImage StatusNotifierHost::image(const QString &id) const {
    bool valid = false;
    const auto key = id.section('/', 0, 0).toULongLong(&valid);
    const auto found = std::find_if(m_items.cbegin(), m_items.cend(),
                                    [key](const auto &item) { return item.key == key; });
    if (!valid || found == m_items.cend())
        return {};
    const auto &item = *found;
    if (!item.icon.isNull())
        return item.icon;
    QImage fallback(32, 32, QImage::Format_ARGB32_Premultiplied);
    fallback.fill(Qt::transparent);
    QPainter painter(&fallback);
    painter.setPen(QColor("#28669c"));
    painter.drawText(fallback.rect(), Qt::AlignCenter, item.title.left(1));
    return fallback;
}
void StatusNotifierHost::invokeItem(const QString &id, const QVariantList &args,
                                    const QString &method) {
    if (!m_items.contains(id))
        return;
    const auto item = m_items.value(id);
    auto request = QDBusMessage::createMethodCall(item.owner, item.path, itemInterface, method);
    request.setArguments(args);
    auto *pending = new QDBusPendingCallWatcher(m_bus.asyncCall(request, 2000), this);
    connect(pending, &QDBusPendingCallWatcher::finished, this,
            [this](QDBusPendingCallWatcher *call) {
                const QDBusPendingReply<> reply = *call;
                if (reply.isError())
                    emit requestRejected(tr("The application could not open its tray action"));
                call->deleteLater();
            });
}
void StatusNotifierHost::activate(const QString &id, int x, int y, bool secondary) {
    const auto method = secondary                ? "SecondaryActivate"
                        : m_items.value(id).menu ? "ContextMenu"
                                                 : "Activate";
    invokeItem(id, {x, y}, QString::fromLatin1(method));
}
void StatusNotifierHost::contextMenu(const QString &id, int x, int y) {
    invokeItem(id, {x, y}, "ContextMenu");
}
QImage TrayIconProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize) {
    auto image = m_host->image(id);
    if (size)
        *size = image.size();
    if (!requestedSize.isEmpty() && !image.isNull())
        image = image.scaled(requestedSize.boundedTo(QSize(128, 128)), Qt::KeepAspectRatio,
                             Qt::SmoothTransformation);
    return image;
}
} // namespace klde
