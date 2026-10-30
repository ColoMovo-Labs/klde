// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "ApplicationEntry.h"
#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <QtQml/qqmlregistration.h>

namespace klde {
class ApplicationModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.applications")
    Q_PROPERTY(bool preview READ preview NOTIFY modeChanged)
  public:
    enum Role : quint16 {
        AppIdRole = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        IconRole,
        KeywordsRole,
        RunningRole,
        ActiveRole,
        OriginRole,
        PinnedRole
    };
    Q_ENUM(Role)
    explicit ApplicationModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    bool activate(const QString &appId);
    Q_INVOKABLE QString nameFor(const QString &appId) const;
    void resetPreview(const QString &appId);
    void setAndroidSource(bool enabled);
    QString activeId() const;
    bool preview() const { return m_preview; }
    void replaceSystemApplications(const QList<ApplicationEntry> &applications);
    void setRuntimeApplications(const QList<ApplicationEntry> &applications);
    Q_INVOKABLE bool isPinned(const QString &appId) const;
    Q_INVOKABLE bool canPin(const QString &appId) const;
    Q_INVOKABLE void setPinned(const QString &appId, bool pinned);
  signals:
    void activeChanged();
    void modeChanged();
    void pinRequested(const QString &appId, bool pinned);

  private:
    QList<ApplicationEntry> m_applications;
    QList<ApplicationEntry> m_catalog;
    QList<ApplicationEntry> m_runtime;
    void reconcileSystemApplications();
    bool m_preview = true;
};

class DockApplicationModel : public QSortFilterProxyModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.dockApplications")
  public:
    explicit DockApplicationModel(ApplicationModel *source, QObject *parent = nullptr);

  protected:
    bool filterAcceptsRow(int row, const QModelIndex &parent) const override;
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
