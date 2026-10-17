// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

namespace klde {
class SystemStateModel : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.state")
    Q_PROPERTY(QVariantMap snapshot READ snapshot NOTIFY changed)
    Q_PROPERTY(bool ready READ ready CONSTANT)
  public:
    explicit SystemStateModel(QObject *parent = nullptr);
    ~SystemStateModel() override;
    QVariantMap snapshot() const { return m_snapshot; }
    bool ready() const { return !m_baseline.isEmpty(); }
    QVariantMap baseline() const { return m_baseline; }
    Q_INVOKABLE QVariant value(const QString &path) const;
    Q_INVOKABLE bool requestValue(const QString &path, const QVariant &value);
    Q_INVOKABLE bool advanceMinutes(int minutes);
    bool replacePreview(const QVariantMap &snapshot);
    static QVariant lookup(const QVariantMap &map, const QString &path);
    static void assign(QVariantMap &map, const QString &path, const QVariant &value);
    bool valid(const QString &path, const QVariant &value) const;
  signals:
    void changed();
    void valueEdited(const QString &path);

  private:
    QVariantMap m_baseline;
    QVariantMap m_snapshot;
};
class MockScenarioManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.mockScenarios")
    Q_PROPERTY(QVariantList scenarios READ scenarios CONSTANT)
    Q_PROPERTY(QString activeId READ activeId NOTIFY applied)
  public:
    explicit MockScenarioManager(SystemStateModel *state, QObject *parent = nullptr);
    QVariantList scenarios() const { return m_scenarios; }
    QString activeId() const { return m_active; }
    Q_INVOKABLE bool apply(const QString &id);
  signals:
    void applied();

  private:
    SystemStateModel *m_state;
    QVariantList m_scenarios;
    QString m_active;
};
} // namespace klde
