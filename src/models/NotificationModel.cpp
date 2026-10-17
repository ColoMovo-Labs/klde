// SPDX-License-Identifier: GPL-3.0-or-later
#include "NotificationModel.h"
#include <algorithm>
namespace klde {
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
    default:
        return {};
    }
}
QHash<int, QByteArray> NotificationModel::roleNames() const {
    return {{IdRole, "notificationId"},
            {SourceRole, "sourceName"},
            {TitleRole, "titleId"},
            {BodyRole, "bodyId"},
            {SeverityRole, "severity"}};
}
void NotificationModel::seedDemo(int requestedCount, const QString &context) {
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
        m_records.append({QStringLiteral("fixture-%1").arg(i), QStringLiteral("Preview Studio"),
                          prefix + key + ".title", prefix + key + ".body", critical ? 2 : 0});
    }
    endResetModel();
    emit countChanged();
}
bool NotificationModel::dismiss(const QString &id) {
    for (int i = 0; i < count(); ++i)
        if (m_records.at(i).id == id) {
            beginRemoveRows({}, i, i);
            m_records.removeAt(i);
            endRemoveRows();
            emit countChanged();
            return true;
        }
    return false;
}
void NotificationModel::clearAll() {
    if (m_records.isEmpty())
        return;
    beginResetModel();
    m_records.clear();
    endResetModel();
    emit countChanged();
}
} // namespace klde
