// SPDX-License-Identifier: GPL-3.0-or-later
#include "NotificationServer.h"
#include <QCoreApplication>
#include <QDBusArgument>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QFileInfo>
#include <QImageReader>
#include <QTextDocument>
#include <QUrl>
#include <QXmlStreamReader>
#include <algorithm>

namespace {
constexpr QLatin1StringView service("org.freedesktop.Notifications");
constexpr QLatin1StringView objectPath("/org/freedesktop/Notifications");
constexpr QLatin1StringView locker("org.freedesktop.ScreenSaver");
QString safeMarkup(const QString &body) {
    QXmlStreamReader reader(QStringLiteral("<body>") + body + QStringLiteral("</body>"));
    QString result;
    while (!reader.atEnd()) {
        reader.readNext();
        const auto tag = reader.name();
        if (reader.isCharacters())
            result +=
                reader.text().toString().toHtmlEscaped().replace('\n', QStringLiteral("<br/>"));
        else if (reader.isStartElement()) {
            if (tag == u"b" || tag == u"i" || tag == u"u")
                result += '<' + tag.toString() + '>';
            else if (tag == u"a") {
                const QUrl url(reader.attributes().value("href").toString());
                if (QStringList{"https", "http", "mailto"}.contains(url.scheme().toLower()))
                    result += QStringLiteral("<a href=\"%1\">").arg(url.toString().toHtmlEscaped());
                else
                    result += QStringLiteral("<a>");
            } else if (tag == u"img")
                result += reader.attributes().value("alt").toString().toHtmlEscaped();
        } else if (reader.isEndElement()) {
            if (tag == u"b" || tag == u"i" || tag == u"u")
                result += "</" + tag.toString() + '>';
            else if (tag == u"a")
                result += QStringLiteral("</a>");
        }
    }
    // Malformed markup stays inert and readable; no HTML/image resource loading.
    return reader.hasError() ? body.toHtmlEscaped().replace('\n', QStringLiteral("<br/>")) : result;
}
QImage localImage(QString path) {
    if (path.startsWith("file:"))
        path = QUrl(path).toLocalFile();
    const QFileInfo info(path);
    if (!info.isAbsolute() || !info.isFile() || info.size() > qint64(2) * 1024 * 1024)
        return {};
    QImageReader reader(path);
    const auto size = reader.size();
    if (!size.isValid() || size.width() > 1024 || size.height() > 1024)
        return {};
    return reader.read();
}
QImage imageHint(const QVariant &value) {
    if (value.metaType() != QMetaType::fromType<QDBusArgument>())
        return {};
    const auto argument = value.value<QDBusArgument>();
    if (argument.currentSignature() != QStringLiteral("(iiibiiay)"))
        return {};
    int width = 0, height = 0, stride = 0, bits = 0, channels = 0;
    bool alpha = false;
    QByteArray bytes;
    argument.beginStructure();
    argument >> width >> height >> stride >> alpha >> bits >> channels >> bytes;
    argument.endStructure();
    if (width <= 0 || height <= 0 || width > 1024 || height > 1024 || bits != 8 ||
        channels != (alpha ? 4 : 3) || stride < qint64(width) * channels ||
        bytes.size() > qsizetype(4) * 1024 * 1024 ||
        qint64(stride) * (height - 1) + qint64(width) * channels > bytes.size())
        return {};
    QImage result(width, height, QImage::Format_ARGB32);
    for (int y = 0; y < height; ++y) {
        auto *row = reinterpret_cast<QRgb *>(result.scanLine(y));
        const auto *source =
            reinterpret_cast<const uchar *>(bytes.constData()) + qsizetype(y) * stride;
        for (int x = 0; x < width; ++x) {
            const auto *pixel = source + qsizetype(x) * channels;
            row[x] = qRgba(pixel[0], pixel[1], pixel[2], alpha ? pixel[3] : 255);
        }
    }
    return result;
}
} // namespace
namespace klde {
NotificationServer::NotificationServer(NotificationModel *model, const QDBusConnection &bus,
                                       QObject *parent)
    : QObject(parent), m_model(model), m_bus(bus),
      m_lockerWatcher(locker, bus, QDBusServiceWatcher::WatchForOwnerChange, this) {
    connect(model, &NotificationModel::closed, this, &NotificationServer::NotificationClosed);
    connect(model, &NotificationModel::actionInvoked, this, &NotificationServer::ActionInvoked);
    connect(&m_lockerWatcher, &QDBusServiceWatcher::serviceOwnerChanged, this, [this] {
        m_model->setLocked(true);
        queryLocker();
    });
}
NotificationServer::~NotificationServer() {
    if (m_owned) {
        m_bus.unregisterObject(objectPath);
        m_bus.unregisterService(service);
    }
}
bool NotificationServer::start() {
    if (m_owned)
        return true;
    if (!m_bus.isConnected() || !m_bus.interface()) {
        m_model->setServiceState(false, QStringLiteral("bus-unavailable"));
        return false;
    }
    const auto occupied = m_bus.interface()->isServiceRegistered(service);
    if (!occupied.isValid()) {
        m_model->setServiceState(false, QStringLiteral("bus-unavailable"));
        return false;
    }
    // Also protect an existing object on this very connection: unregistering
    // after a duplicate object-path failure would otherwise remove its name.
    if (occupied.value()) {
        m_model->setServiceState(false, QStringLiteral("another-server"));
        return false;
    }
    if (!m_bus.registerService(service)) {
        m_model->setServiceState(false, QStringLiteral("another-server"));
        return false;
    }
    if (!m_bus.registerObject(objectPath, this,
                              QDBusConnection::ExportScriptableSlots |
                                  QDBusConnection::ExportAllSignals)) {
        m_bus.unregisterService(service);
        m_model->setServiceState(false, QStringLiteral("registration-failed"));
        return false;
    }
    m_owned = true;
    m_model->setServiceState(true, QStringLiteral("ready"));
    m_bus.connect(locker, QStringLiteral("/ScreenSaver"), locker, QStringLiteral("ActiveChanged"),
                  this, SLOT(lockerActiveChanged(bool)));
    queryLocker();
    return true;
}
void NotificationServer::queryLocker() {
    const auto revision = ++m_lockRevision;
    const auto request = QDBusMessage::createMethodCall(locker, QStringLiteral("/ScreenSaver"),
                                                        locker, QStringLiteral("GetActive"));
    auto *watcher = new QDBusPendingCallWatcher(m_bus.asyncCall(request), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, revision] {
        const QDBusPendingReply<bool> reply = *watcher;
        // Keep contents suppressed if the lock service cannot confirm its state.
        if (!reply.isError() && revision == m_lockRevision)
            m_model->setLocked(reply.value());
        watcher->deleteLater();
    });
}
void NotificationServer::lockerActiveChanged(bool active) {
    ++m_lockRevision;
    m_model->setLocked(active);
}
// The standardized D-Bus ABI fixes this positional signature.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
uint NotificationServer::Notify(const QString &appName, uint replacesId, const QString &appIcon,
                                const QString &summary, const QString &body,
                                const QStringList &actions, const QVariantMap &hints,
                                int expireTimeout) {
    if (appName.size() > 256 || summary.size() > 1024 || body.size() > 16384 ||
        actions.size() > 32 || actions.size() % 2) {
        sendErrorReply(QDBusError::InvalidArgs,
                       QStringLiteral("Notification payload exceeds supported bounds"));
        return 0;
    }
    NotificationModel::Incoming incoming;
    incoming.sender = message().service();
    incoming.source = appName.isEmpty() ? QStringLiteral("Application") : appName;
    incoming.title = summary;
    incoming.markup = safeMarkup(body);
    QTextDocument plain;
    plain.setHtml(incoming.markup);
    incoming.body = plain.toPlainText();
    incoming.urgency = std::clamp(hints.value("urgency", 1).toInt(), 0, 2);
    incoming.expireTimeout = incoming.urgency == 2 ? 0 : std::clamp(expireTimeout, -1, 86400000);
    incoming.resident = hints.value("resident").toBool();
    incoming.transient = hints.value("transient").toBool();
    for (int index = 0; index + 1 < actions.size(); index += 2) {
        if (actions.at(index).size() > 128 || actions.at(index + 1).size() > 256)
            continue;
        incoming.actions.append(
            QVariantMap{{"key", actions.at(index)}, {"label", actions.at(index + 1)}});
    }
    for (const auto *hint : {"image-data", "image_data", "icon_data"}) {
        incoming.image = imageHint(hints.value(QLatin1StringView(hint)));
        if (!incoming.image.isNull())
            break;
    }
    if (incoming.image.isNull())
        incoming.image =
            localImage(hints.value("image-path", hints.value("image_path")).toString());
    if (incoming.image.isNull() && (appIcon.startsWith('/') || appIcon.startsWith("file:")))
        incoming.image = localImage(appIcon);
    else if (!appIcon.contains('/') && !appIcon.contains(':'))
        incoming.appIcon = appIcon.left(256);
    if (incoming.image.width() > 128 || incoming.image.height() > 128)
        incoming.image =
            incoming.image.scaled(QSize(128, 128), Qt::KeepAspectRatio, Qt::SmoothTransformation);
    return m_model->receive(replacesId, incoming);
}
void NotificationServer::CloseNotification(uint id) {
    if (!m_model->close(id, 3))
        sendErrorReply(QDBusError::InvalidArgs, QString{});
}
QStringList NotificationServer::GetCapabilities() const {
    return {"body", "body-markup", "actions", "icon-static", "persistence"};
}
// The standardized D-Bus ABI fixes these output arguments.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
QString NotificationServer::GetServerInformation(QString &vendor, QString &version,
                                                 QString &specVersion) const {
    vendor = QStringLiteral("ColoMovo-Labs");
    version = QCoreApplication::applicationVersion().isEmpty()
                  ? QStringLiteral("development")
                  : QCoreApplication::applicationVersion();
    specVersion = QStringLiteral("1.2");
    return QStringLiteral("owoDE");
}
QImage NotificationIconProvider::requestImage(const QString &id, QSize *size,
                                              const QSize &requested) {
    const auto image = m_model->image(id.section('/', 0, 0).toUInt(),
                                      requested.isValid() ? requested : QSize(48, 48));
    if (size)
        *size = image.size();
    return image;
}
} // namespace klde
