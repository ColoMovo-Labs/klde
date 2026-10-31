// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QAbstractListModel>
#include <QPointer>
#include <QScreen>
#include <QtQml/qqmlregistration.h>

namespace klde {

// One row per QScreen, kept in step with screenAdded/screenRemoved and
// primaryScreenChanged so QML can create and destroy per-output surfaces
// without rebuilding the surfaces of outputs that did not change.
class ScreenModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.screens")
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString primaryName READ primaryName NOTIFY primaryChanged)

  public:
    enum Role : quint16 {
        ScreenRole = Qt::UserRole + 1,
        NameRole,
        PrimaryRole,
        GeometryRole,
        ScaleRole,
        RefreshRateRole,
        ManufacturerRole,
        ModelNameRole,
        PhysicalSizeRole,
    };
    Q_ENUM(Role)

    explicit ScreenModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const { return static_cast<int>(m_screens.size()); }
    QString primaryName() const;
    // Snapshot of every role for one screen, for the read-only Displays page.
    Q_INVOKABLE QVariantMap get(int row) const;

  signals:
    void countChanged();
    void primaryChanged();

  private:
    void add(QScreen *screen);
    void remove(QScreen *screen);
    void refresh(QScreen *screen);

    QList<QPointer<QScreen>> m_screens;
};

} // namespace klde
