// SPDX-License-Identifier: GPL-3.0-or-later
#include "ScreenModel.h"

#include <QGuiApplication>

namespace klde {

ScreenModel::ScreenModel(QObject *parent) : QAbstractListModel(parent) {
    auto *application = qobject_cast<QGuiApplication *>(QCoreApplication::instance());
    if (application == nullptr)
        return;
    for (auto *screen : QGuiApplication::screens())
        add(screen);
    connect(application, &QGuiApplication::screenAdded, this, &ScreenModel::add);
    connect(application, &QGuiApplication::screenRemoved, this, &ScreenModel::remove);
    connect(application, &QGuiApplication::primaryScreenChanged, this, [this] {
        if (!m_screens.isEmpty())
            emit dataChanged(index(0), index(count() - 1), {PrimaryRole});
        emit primaryChanged();
    });
}

int ScreenModel::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : count();
}

QHash<int, QByteArray> ScreenModel::roleNames() const {
    return {{ScreenRole, "output"},
            {NameRole, "name"},
            {PrimaryRole, "primary"},
            {GeometryRole, "geometry"},
            {ScaleRole, "pixelRatio"},
            {RefreshRateRole, "refreshRate"},
            {ManufacturerRole, "manufacturer"},
            {ModelNameRole, "modelName"},
            {PhysicalSizeRole, "physicalSize"}};
}

QVariant ScreenModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= count())
        return {};
    QScreen *screen = m_screens.at(index.row()).data();
    if (screen == nullptr)
        return {};
    switch (role) {
    case ScreenRole:
        return QVariant::fromValue(screen);
    case NameRole:
        return screen->name();
    case PrimaryRole:
        return screen == QGuiApplication::primaryScreen();
    case GeometryRole:
        return screen->geometry();
    case ScaleRole:
        return screen->devicePixelRatio();
    case RefreshRateRole:
        return screen->refreshRate();
    case ManufacturerRole:
        return screen->manufacturer();
    case ModelNameRole:
        return screen->model();
    case PhysicalSizeRole:
        return screen->physicalSize();
    default:
        return {};
    }
}

QVariantMap ScreenModel::get(int row) const {
    QVariantMap result;
    const auto names = roleNames();
    for (auto role = names.cbegin(); role != names.cend(); ++role)
        result.insert(QString::fromLatin1(role.value()), data(index(row), role.key()));
    return result;
}

QString ScreenModel::primaryName() const {
    const auto *screen = QGuiApplication::primaryScreen();
    return screen ? screen->name() : QString();
}

void ScreenModel::add(QScreen *screen) {
    if (screen == nullptr || m_screens.contains(screen))
        return;
    const auto row = count();
    beginInsertRows({}, row, row);
    m_screens.append(screen);
    endInsertRows();
    const auto changed = [this, screen] { refresh(screen); };
    connect(screen, &QScreen::geometryChanged, this, changed);
    connect(screen, &QScreen::physicalDotsPerInchChanged, this, changed);
    connect(screen, &QScreen::logicalDotsPerInchChanged, this, changed);
    connect(screen, &QScreen::refreshRateChanged, this, changed);
    emit countChanged();
}

void ScreenModel::remove(QScreen *screen) {
    const auto row = static_cast<int>(m_screens.indexOf(screen));
    if (row < 0)
        return;
    disconnect(screen, nullptr, this, nullptr);
    beginRemoveRows({}, row, row);
    m_screens.removeAt(row);
    endRemoveRows();
    emit countChanged();
}

void ScreenModel::refresh(QScreen *screen) {
    const auto row = static_cast<int>(m_screens.indexOf(screen));
    if (row >= 0)
        emit dataChanged(index(row), index(row));
}

} // namespace klde
