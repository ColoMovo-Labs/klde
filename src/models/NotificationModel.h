// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QAbstractListModel>
#include <QtQml/qqmlregistration.h>
namespace klde {
class NotificationModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.notifications")
    Q_PROPERTY(int count READ count NOTIFY countChanged)
  public:
    enum Role : quint16 {
        IdRole = Qt::UserRole + 1,
        SourceRole,
        TitleRole,
        BodyRole,
        SeverityRole
    };
    explicit NotificationModel(QObject *parent = nullptr) : QAbstractListModel(parent) {}
    int rowCount(const QModelIndex &parent = {}) const override {
        return parent.isValid() ? 0 : static_cast<int>(m_records.size());
    }
    int count() const { return rowCount(); }
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    void seedDemo(int count, const QString &context);
    Q_INVOKABLE bool dismiss(const QString &id);
    Q_INVOKABLE void clearAll();
  signals:
    void countChanged();

  private:
    struct Record {
        QString id;
        QString source;
        QString titleId;
        QString bodyId;
        int severity;
    };
    QList<Record> m_records;
};
} // namespace klde
