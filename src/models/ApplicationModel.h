// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <QtQml/qqmlregistration.h>

namespace klde {
class ApplicationModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.applications")
  public:
    enum Role {
        AppIdRole = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        IconRole,
        KeywordsRole,
        RunningRole,
        ActiveRole
    };
    Q_ENUM(Role)
    explicit ApplicationModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    bool activate(const QString &appId);
    QString nameFor(const QString &appId) const;

  private:
    struct Application {
        QString id;
        QString name;
        QString description;
        QString icon;
        QString keywords;
        bool running = false;
        bool active = false;
    };
    QList<Application> m_applications;
};

class ApplicationFilterModel : public QSortFilterProxyModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.search")
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
  public:
    explicit ApplicationFilterModel(ApplicationModel *source, QObject *parent = nullptr);
    QString query() const { return m_query; }
    int count() const { return rowCount(); }
    void setQuery(const QString &query);
    Q_INVOKABLE QString idAt(int row) const;
  signals:
    void queryChanged();
    void countChanged();

  protected:
    bool filterAcceptsRow(int row, const QModelIndex &parent) const override;

  private:
    QString m_query;
};
} // namespace klde
