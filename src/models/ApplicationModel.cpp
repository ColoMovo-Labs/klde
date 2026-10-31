// SPDX-License-Identifier: GPL-3.0-or-later
#include "ApplicationModel.h"
#include <QHash>
#include <algorithm>
#include <utility>

namespace klde {
ApplicationModel::ApplicationModel(QObject *parent) : QAbstractListModel(parent) {
    m_applications = {
        {"files", "Files", "Your everyday places", "folder",
         "home documents folders 文件 文档 文件夹 wenjian", true, false},
        {"web", "Browser", "A little window to the world", "globe",
         "internet web search 浏览器 网页 liulanqi"},
        {"terminal", "Terminal", "Make something happen", "terminal",
         "console command shell 终端 命令 zhongduan", true, true},
        {"notes", "Notes", "Keep a thought close", "note", "write text editor 笔记 文本 biji"},
        {"music", "Music", "Find your rhythm", "music", "audio listen sound 音乐 yinyue"},
        {"settings", "Settings", "Make this space yours", "settings",
         "preferences appearance 设置 shezhi"}};
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
    case OriginRole:
        return app.origin;
    case PinnedRole:
        return app.pinned;
    default:
        return {};
    }
}
QHash<int, QByteArray> ApplicationModel::roleNames() const {
    return {{AppIdRole, "appId"},   {NameRole, "displayName"},  {DescriptionRole, "description"},
            {IconRole, "iconName"}, {KeywordsRole, "keywords"}, {RunningRole, "running"},
            {ActiveRole, "active"}, {OriginRole, "origin"},     {PinnedRole, "pinned"}};
}
QString ApplicationModel::nameFor(const QString &appId) const {
    const auto found =
        std::find_if(m_applications.cbegin(), m_applications.cend(),
                     [&appId](const ApplicationEntry &app) { return app.id == appId; });
    return found == m_applications.cend() ? QString{} : found->name;
}
QString ApplicationModel::activeId() const {
    for (const auto &app : m_applications)
        if (app.active)
            return app.id;
    return QStringLiteral("desktop");
}
void ApplicationModel::resetPreview(const QString &appId) {
    if (!m_preview)
        return;
    for (auto &app : m_applications) {
        app.active = app.id == appId;
        app.running = app.active || app.id == "files" || app.id == "terminal";
    }
    emit dataChanged(index(0), index(rowCount() - 1), {RunningRole, ActiveRole});
    emit activeChanged();
}
void ApplicationModel::setAndroidSource(bool enabled) {
    if (!m_preview)
        return;
    const bool present = !m_applications.isEmpty() && m_applications.last().origin == "android";
    if (present == enabled)
        return;
    const int row = static_cast<int>(m_applications.size());
    if (enabled) {
        beginInsertRows({}, row, row);
        m_applications.append({"android-sketch", tr("Android Sketch"),
                               tr("Optional Android app preview"), "note",
                               "android waydroid drawing 安卓 绘画", false, false, "android"});
        endInsertRows();
    } else {
        const bool active = m_applications.last().active;
        beginRemoveRows({}, row - 1, row - 1);
        m_applications.removeLast();
        endRemoveRows();
        if (active)
            emit activeChanged();
    }
}
bool ApplicationModel::activate(const QString &appId) {
    if (!m_preview || nameFor(appId).isEmpty()) {
        return false;
    }
    for (auto &app : m_applications) {
        app.active = app.id == appId;
        app.running = app.running || app.active;
    }
    emit dataChanged(index(0), index(rowCount() - 1), {RunningRole, ActiveRole});
    emit activeChanged();
    return true;
}

void ApplicationModel::replaceSystemApplications(const QList<ApplicationEntry> &applications) {
    const bool changedMode = m_preview;
    m_preview = false;
    m_catalog = applications;
    reconcileSystemApplications();
    if (changedMode)
        emit modeChanged();
}
void ApplicationModel::setRuntimeApplications(const QList<ApplicationEntry> &applications) {
    if (m_preview)
        return;
    m_runtime = applications;
    reconcileSystemApplications();
}
void ApplicationModel::reconcileSystemApplications() {
    auto next = m_catalog;
    QList<ApplicationEntry> unmatched;
    for (auto &entry : next) {
        entry.running = false;
        entry.active = false;
    }
    for (const auto &runtime : std::as_const(m_runtime)) {
        auto entry = std::find_if(next.begin(), next.end(),
                                  [&runtime](const auto &item) { return item.id == runtime.id; });
        if (entry == next.end())
            unmatched.append(runtime);
        else {
            entry->running = runtime.running;
            entry->active = runtime.active;
        }
    }
    QHash<QString, qsizetype> positions;
    for (qsizetype row = 0; row < m_applications.size(); ++row)
        positions.insert(m_applications.at(row).id, row);
    std::stable_sort(unmatched.begin(), unmatched.end(),
                     [this, &positions](const auto &a, const auto &b) {
                         return positions.value(a.id, m_applications.size()) <
                                positions.value(b.id, m_applications.size());
                     });
    next.append(unmatched);
    const auto previousActive = activeId();
    const auto previousName = activeName();
    bool structure = next.size() != m_applications.size();
    for (qsizetype row = 0; !structure && row < next.size(); ++row) {
        const auto &before = m_applications.at(row);
        const auto &after = next.at(row);
        structure = before.id != after.id || before.name != after.name ||
                    before.description != after.description || before.icon != after.icon ||
                    before.keywords != after.keywords || before.origin != after.origin ||
                    before.pinned != after.pinned;
    }
    if (structure) {
        beginResetModel();
        m_applications = next;
        endResetModel();
    } else {
        for (qsizetype row = 0; row < next.size(); ++row) {
            if (m_applications.at(row).running != next.at(row).running ||
                m_applications.at(row).active != next.at(row).active) {
                m_applications[row] = next.at(row);
                emit dataChanged(index(static_cast<int>(row)), index(static_cast<int>(row)),
                                 {RunningRole, ActiveRole});
            }
        }
    }
    if (previousActive != activeId() || previousName != activeName())
        emit activeChanged();
}
bool ApplicationModel::isPinned(const QString &appId) const {
    for (const auto &app : m_applications)
        if (app.id == appId)
            return app.pinned;
    return false;
}
void ApplicationModel::setPinned(const QString &appId, bool pinned) {
    if (canPin(appId))
        emit pinRequested(appId, pinned);
}
bool ApplicationModel::canPin(const QString &appId) const {
    return !m_preview && std::any_of(m_catalog.cbegin(), m_catalog.cend(),
                                     [&appId](const auto &app) { return app.id == appId; });
}
DockApplicationModel::DockApplicationModel(ApplicationModel *source, QObject *parent)
    : QSortFilterProxyModel(parent) {
    setSourceModel(source);
    setDynamicSortFilter(true);
}
bool DockApplicationModel::filterAcceptsRow(int row, const QModelIndex &parent) const {
    const auto *applications = qobject_cast<ApplicationModel *>(sourceModel());
    const auto item = sourceModel()->index(row, 0, parent);
    return applications->preview() ||
           sourceModel()->data(item, ApplicationModel::PinnedRole).toBool() ||
           sourceModel()->data(item, ApplicationModel::RunningRole).toBool();
}

ApplicationFilterModel::ApplicationFilterModel(ApplicationModel *source, QObject *parent)
    : QSortFilterProxyModel(parent) {
    setSourceModel(source);
    setDynamicSortFilter(true);
    connect(this, &QAbstractItemModel::rowsInserted, this, [this] { emit countChanged(); });
    connect(this, &QAbstractItemModel::rowsRemoved, this, [this] { emit countChanged(); });
    connect(this, &QAbstractItemModel::modelReset, this, [this] { emit countChanged(); });
}
void ApplicationFilterModel::setQuery(const QString &query) {
    const auto normalized = query.simplified();
    if (normalized != m_query) {
        m_query = normalized;
        invalidateRowsFilter();
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
