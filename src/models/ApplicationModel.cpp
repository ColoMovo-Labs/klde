// SPDX-License-Identifier: GPL-3.0-or-later
#include "ApplicationModel.h"
#include <algorithm>

namespace klde {
ApplicationModel::ApplicationModel(QObject *parent) : QAbstractListModel(parent) {
    m_applications = {
        {"files", "Files", "Your everyday places", "folder", "home documents folders", true, false},
        {"web", "Browser", "A little window to the world", "globe", "internet web search"},
        {"terminal", "Terminal", "Make something happen", "terminal", "console command shell", true,
         true},
        {"notes", "Notes", "Keep a thought close", "note", "write text editor"},
        {"music", "Music", "Find your rhythm", "music", "audio listen sound"},
        {"settings", "Settings", "Make this space yours", "settings", "preferences appearance"}};
}
int ApplicationModel::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : static_cast<int>(m_applications.size());
}
QVariant ApplicationModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_applications.size()) {
        return {};
    }
    const auto &app = m_applications.at(index.row());
    switch (role) {
    case AppIdRole:
        return app.id;
    case Qt::DisplayRole:
    case NameRole:
        return app.name;
    case DescriptionRole:
        return app.description;
    case IconRole:
        return app.icon;
    case KeywordsRole:
        return app.keywords;
    case RunningRole:
        return app.running;
    case ActiveRole:
        return app.active;
    default:
        return {};
    }
}
QHash<int, QByteArray> ApplicationModel::roleNames() const {
    return {{AppIdRole, "appId"},   {NameRole, "displayName"},  {DescriptionRole, "description"},
            {IconRole, "iconName"}, {KeywordsRole, "keywords"}, {RunningRole, "running"},
            {ActiveRole, "active"}};
}
QString ApplicationModel::nameFor(const QString &appId) const {
    const auto found = std::find_if(m_applications.cbegin(), m_applications.cend(),
                                    [&appId](const Application &app) { return app.id == appId; });
    return found == m_applications.cend() ? QString{} : found->name;
}
bool ApplicationModel::activate(const QString &appId) {
    if (nameFor(appId).isEmpty()) {
        return false;
    }
    for (auto &app : m_applications) {
        app.active = app.id == appId;
        app.running = app.running || app.active;
    }
    emit dataChanged(index(0), index(rowCount() - 1), {RunningRole, ActiveRole});
    return true;
}

ApplicationFilterModel::ApplicationFilterModel(ApplicationModel *source, QObject *parent)
    : QSortFilterProxyModel(parent) {
    setSourceModel(source);
    setDynamicSortFilter(true);
}
void ApplicationFilterModel::setQuery(const QString &query) {
    const auto normalized = query.simplified();
    if (normalized != m_query) {
        m_query = normalized;
        invalidate();
        emit queryChanged();
        emit countChanged();
    }
}
bool ApplicationFilterModel::filterAcceptsRow(int row, const QModelIndex &parent) const {
    const auto sourceIndex = sourceModel()->index(row, 0, parent);
    const QList<int> roles{ApplicationModel::NameRole, ApplicationModel::DescriptionRole,
                           ApplicationModel::KeywordsRole};
    return std::any_of(roles.cbegin(), roles.cend(), [this, &sourceIndex](int role) {
        return sourceModel()
            ->data(sourceIndex, role)
            .toString()
            .contains(m_query, Qt::CaseInsensitive);
    });
}
QString ApplicationFilterModel::idAt(int row) const {
    return data(index(row, 0), ApplicationModel::AppIdRole).toString();
}
} // namespace klde
