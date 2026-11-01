// SPDX-License-Identifier: GPL-3.0-or-later
#include "NotificationModel.h"
#include <QIcon>
#include <algorithm>
#include <limits>

namespace klde {
NotificationModel::NotificationModel(QObject *parent) : QAbstractListModel(parent) {
    m_expiryTimer.setSingleShot(true);
    m_popupTimer.setSingleShot(true);
    connect(&m_popupTimer, &QTimer::timeout, this, &NotificationModel::advancePopup);
    connect(&m_expiryTimer, &QTimer::timeout, this, [this] {
        QList<uint> expired;
        for (const auto &record : std::as_const(m_records))
            if (!record.demo && record.deadline.hasExpired())
                expired.append(record.id.toUInt());
        for (const auto id : expired)
            close(id, 1);
        rescheduleExpiry();
    });
}
int NotificationModel::unreadCount() const {
    return static_cast<int>(std::count_if(m_records.cbegin(), m_records.cend(),
                                          [](const auto &record) { return record.unread; }));
}
QVariant NotificationModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= count())
        return {};
    const auto &item = m_records.at(index.row());
    switch (role) {
    case IdRole:
        return item.id;
    case SourceRole:
        return item.source;
    case TitleRole:
        return item.titleId;
    case BodyRole:
        return item.bodyId;
    case SeverityRole:
        return item.severity;
    case TitleTextRole:
        return item.incoming.title;
    case BodyTextRole:
        return m_locked ? QString{} : item.incoming.body;
    case BodyMarkupRole:
        return m_locked ? QString{} : item.incoming.markup;
    case IconRole:
        return item.demo ? QStringLiteral("bell") : presentation(item).value("icon");
    case ActionsRole:
        return item.incoming.actions;
    case DemoRole:
        return item.demo;
    case GroupStartRole:
        return index.row() == 0 || m_records.at(index.row() - 1).source != item.source;
    default:
        return {};
    }
}
QHash<int, QByteArray> NotificationModel::roleNames() const {
    return {{IdRole, "notificationId"},
            {SourceRole, "sourceName"},
            {TitleRole, "titleId"},
            {BodyRole, "bodyId"},
            {SeverityRole, "severity"},
            {TitleTextRole, "titleText"},
            {BodyTextRole, "bodyText"},
            {BodyMarkupRole, "bodyMarkup"},
            {IconRole, "notificationIcon"},
            {ActionsRole, "notificationActions"},
            {DemoRole, "demo"},
            {GroupStartRole, "groupStart"}};
}
void NotificationModel::seedDemo(int requestedCount, const QString &context) {
    if (m_native)
        return;
    beginResetModel();
    m_records.clear();
    const int amount = std::clamp(requestedCount, 0, 12);
    for (int i = 0; i < amount; ++i) {
        const auto key = i == 0 && !context.isEmpty() ? context
                         : i % 2 == 0                 ? QStringLiteral("note")
                                                      : QStringLiteral("update");
        const bool critical = key == "battery" || key == "temperature" || key == "session";
        const auto prefix = critical ? QStringLiteral("critical.notification.")
                                     : QStringLiteral("lab.notification.");
        Record record;
        record.id = QStringLiteral("fixture-%1").arg(i);
        record.source = QStringLiteral("Preview Studio");
        record.titleId = prefix + key + ".title";
        record.bodyId = prefix + key + ".body";
        record.severity = critical ? 2 : 0;
        m_records.append(record);
    }
    endResetModel();
    emit countChanged();
}
void NotificationModel::setServiceState(bool available, const QString &status) {
    if (!m_native) {
        stopPopups();
        clearAll();
        m_native = true;
        m_locked = true; // Fail closed until the actual locker answers GetActive.
    }
    m_available = available;
    m_serviceStatus = status;
    emit serviceChanged();
}
uint NotificationModel::receive(uint replacesId, const Incoming &incoming) {
    if (!m_native || !m_available)
        return 0;
    auto found = std::find_if(m_records.begin(), m_records.end(), [&](const auto &record) {
        return record.id.toUInt() == replacesId && record.incoming.sender == incoming.sender;
    });
    uint id = replacesId;
    if (found == m_records.end()) {
        if (count() >= 100) {
            const auto oldest = std::min_element(
                m_records.cbegin(), m_records.cend(),
                [](const auto &a, const auto &b) { return a.id.toUInt() < b.id.toUInt(); });
            close(oldest->id.toUInt(), 4);
        }
        found = m_records.end();
        do {
            ++m_nextId;
        } while (!m_nextId ||
                 std::any_of(m_records.cbegin(), m_records.cend(),
                             [this](const auto &r) { return r.id.toUInt() == m_nextId; }));
        id = m_nextId;
    }
    beginResetModel();
    if (found == m_records.end()) {
        m_records.append(Record{});
        found = std::prev(m_records.end());
    }
    found->id = QString::number(id);
    found->source = incoming.source;
    found->incoming = incoming;
    found->demo = false;
    found->unread = true;
    found->severity = incoming.urgency;
    ++found->revision;
    const int expiry =
        incoming.expireTimeout == -1 ? (incoming.transient ? 5000 : 0) : incoming.expireTimeout;
    found->deadline = expiry > 0 ? QDeadlineTimer(expiry) : QDeadlineTimer(QDeadlineTimer::Forever);
    std::stable_sort(m_records.begin(), m_records.end(), [](const auto &a, const auto &b) {
        const auto order = QString::compare(a.source, b.source, Qt::CaseInsensitive);
        return order == 0 ? a.id.toUInt() > b.id.toUInt() : order < 0;
    });
    endResetModel();
    emit countChanged();
    rescheduleExpiry();
    enqueue(QString::number(id));
    if (incoming.transient && (m_dnd || m_locked))
        QTimer::singleShot(0, this, [this, id] { close(id, 1); });
    return id;
}
QVariantMap NotificationModel::presentation(const Record &r) const {
    return {
        {"id", r.id},
        {"source", r.source},
        {"title", r.incoming.title},
        {"body", m_locked ? QString{} : r.incoming.body},
        {"markup", m_locked ? QString{} : r.incoming.markup},
        {"severity", r.severity},
        {"actions", r.incoming.actions},
        {"demo", r.demo},
        {"titleId", r.titleId},
        {"bodyId", r.bodyId},
        {"icon", r.demo ? QStringLiteral("bell")
                        : QStringLiteral("image://notifications/%1/%2").arg(r.id).arg(r.revision)}};
}
QVariantMap NotificationModel::popup() const {
    if (m_dnd || m_locked || m_current.isEmpty())
        return {};
    for (const auto &record : m_records)
        if (record.id == m_current)
            return presentation(record);
    return {};
}
void NotificationModel::enqueue(const QString &id) {
    if (m_dnd || m_locked)
        return;
    if (m_current == id) {
        m_paused = false;
        m_popupRemaining = 4500;
        const auto value = popup();
        m_popupTimer.stop();
        if (value.value("severity").toInt() != 2)
            m_popupTimer.start(m_popupRemaining);
        emit popupChanged();
        return;
    }
    if (!m_pending.contains(id))
        m_pending.append(id);
    if (m_current.isEmpty())
        advancePopup();
}
void NotificationModel::advancePopup() {
    if (m_paused)
        pausePopup(false);
    const auto previous = m_current;
    m_popupTimer.stop();
    m_current.clear();
    m_paused = false;
    m_popupRemaining = 4500;
    m_expiryRemaining = -1;
    if (!m_dnd && !m_locked) {
        while (!m_pending.isEmpty()) {
            const auto id = m_pending.takeFirst();
            if (std::any_of(m_records.cbegin(), m_records.cend(),
                            [&id](const auto &r) { return r.id == id; })) {
                m_current = id;
                if (popup().value("severity").toInt() != 2)
                    m_popupTimer.start(m_popupRemaining);
                break;
            }
        }
    }
    if (!previous.isEmpty()) {
        const auto finished = std::find_if(m_records.cbegin(), m_records.cend(),
                                           [&previous](const auto &r) { return r.id == previous; });
        if (finished != m_records.cend() && finished->incoming.transient)
            close(previous.toUInt(), 1);
    }
    emit popupChanged();
}
void NotificationModel::pausePopup(bool paused) {
    if (m_paused == paused || m_current.isEmpty())
        return;
    m_paused = paused;
    for (auto &record : m_records) {
        if (record.id != m_current)
            continue;
        if (paused) {
            m_expiryRemaining = record.deadline.remainingTime();
            record.deadline = QDeadlineTimer(QDeadlineTimer::Forever);
        } else if (m_expiryRemaining >= 0)
            record.deadline = QDeadlineTimer(m_expiryRemaining);
    }
    if (paused) {
        if (m_popupTimer.isActive())
            m_popupRemaining = m_popupTimer.remainingTime();
        m_popupTimer.stop();
    } else if (popup().value("severity").toInt() != 2)
        m_popupTimer.start(std::max(1, m_popupRemaining));
    rescheduleExpiry();
}
void NotificationModel::stopPopups() {
    pausePopup(false);
    m_pending.clear();
    m_current.clear();
    m_popupTimer.stop();
    QList<uint> transient;
    for (const auto &record : std::as_const(m_records))
        if (!record.demo && record.incoming.transient)
            transient.append(record.id.toUInt());
    for (const auto id : transient)
        close(id, 1);
    emit popupChanged();
}
void NotificationModel::presentDemoPopup() {
    if (m_native || m_records.isEmpty())
        return;
    m_current = m_records.first().id;
    // A deliberately frozen Visual Lab fixture, not a running system timer.
    m_popupTimer.stop();
    emit popupChanged();
}
void NotificationModel::setDnd(bool enabled) {
    if (m_dnd == enabled)
        return;
    m_dnd = enabled;
    if (enabled)
        stopPopups();
}
void NotificationModel::setLocked(bool locked) {
    if (m_locked == locked)
        return;
    m_locked = locked;
    if (locked)
        stopPopups();
    else
        emit popupChanged();
    if (count())
        emit dataChanged(index(0), index(count() - 1), {BodyTextRole, BodyMarkupRole});
}
bool NotificationModel::close(uint id, uint reason) {
    const auto key = QString::number(id);
    for (int row = 0; row < count(); ++row) {
        if (m_records.at(row).id != key || m_records.at(row).demo)
            continue;
        beginRemoveRows({}, row, row);
        m_records.removeAt(row);
        endRemoveRows();
        m_pending.removeAll(key);
        if (m_current == key)
            advancePopup();
        emit countChanged();
        emit closed(id, reason);
        if (count())
            emit dataChanged(index(0), index(count() - 1), {GroupStartRole});
        rescheduleExpiry();
        return true;
    }
    return false;
}
bool NotificationModel::dismiss(const QString &id) {
    if (m_native)
        return close(id.toUInt(), 2);
    for (int row = 0; row < count(); ++row) {
        if (m_records.at(row).id != id)
            continue;
        beginRemoveRows({}, row, row);
        m_records.removeAt(row);
        endRemoveRows();
        emit countChanged();
        return true;
    }
    return false;
}
void NotificationModel::clearAll() {
    const auto records = m_records;
    for (const auto &record : records)
        dismiss(record.id);
}
bool NotificationModel::invokeAction(const QString &id, const QString &key) {
    for (const auto &record : std::as_const(m_records)) {
        if (record.id != id || record.demo)
            continue;
        const bool valid =
            std::any_of(record.incoming.actions.cbegin(), record.incoming.actions.cend(),
                        [&key](const auto &a) { return a.toMap().value("key").toString() == key; });
        if (!valid)
            return false;
        const bool resident = record.incoming.resident;
        emit actionInvoked(id.toUInt(), key);
        if (!resident)
            close(id.toUInt(), 2);
        return true;
    }
    return false;
}
void NotificationModel::markRead(const QString &id) {
    for (auto &record : m_records)
        if (record.id == id && record.unread) {
            record.unread = false;
            emit countChanged();
            return;
        }
}
void NotificationModel::rescheduleExpiry() {
    qint64 nearest = std::numeric_limits<qint64>::max();
    for (const auto &record : std::as_const(m_records))
        if (!record.demo && !record.deadline.isForever())
            nearest = std::min(nearest, record.deadline.remainingTime());
    m_expiryTimer.stop();
    if (nearest != std::numeric_limits<qint64>::max())
        m_expiryTimer.start(static_cast<int>(std::clamp<qint64>(nearest, 1, 2147483647)));
}
QImage NotificationModel::image(uint id, const QSize &requested) const {
    const auto size = requested.expandedTo(QSize(1, 1)).boundedTo(QSize(256, 256));
    for (const auto &record : m_records)
        if (record.id.toUInt() == id && !record.demo) {
            if (!record.incoming.image.isNull())
                return record.incoming.image.scaled(size, Qt::KeepAspectRatio,
                                                    Qt::SmoothTransformation);
            const auto name = record.incoming.appIcon;
            const auto icon = name.startsWith('/') ? QIcon(name) : QIcon::fromTheme(name);
            if (!icon.isNull())
                return icon.pixmap(size).toImage();
        }
    return QIcon(QStringLiteral(":/assets/icons/bell.svg")).pixmap(size).toImage();
}
} // namespace klde
