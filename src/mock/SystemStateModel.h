// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QHash>
#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>
#include <functional>

namespace klde {
class SystemStateModel : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.state")
    Q_PROPERTY(QVariantMap snapshot READ snapshot NOTIFY changed)
    Q_PROPERTY(QVariantMap alerts READ alerts NOTIFY changed)
    Q_PROPERTY(bool ready READ ready CONSTANT)
    Q_PROPERTY(QStringList livePaths READ livePaths NOTIFY changed)
  public:
    explicit SystemStateModel(QObject *parent = nullptr);
    ~SystemStateModel() override;
    QVariantMap snapshot() const { return m_snapshot; }
    QVariantMap alerts() const;
    bool ready() const { return !m_baseline.isEmpty(); }
    QVariantMap baseline() const { return m_baseline; }
    Q_INVOKABLE QVariant value(const QString &path) const;
    Q_INVOKABLE bool requestValue(const QString &path, const QVariant &value);
    Q_INVOKABLE bool advanceMinutes(int minutes);
    bool replacePreview(const QVariantMap &snapshot);
    static QVariant lookup(const QVariantMap &map, const QString &path);
    static void assign(QVariantMap &map, const QString &path, const QVariant &value);
    bool valid(const QString &path, const QVariant &value) const;
    // Confirmed values from a real system service. A live path is pinned: mock
    // scenarios and preview edits can no longer replace it, so a fixture never
    // masquerades as live state. Returns false for values outside the schema.
    bool publishLive(const QString &path, const QVariant &value);
    bool isLive(const QString &path) const { return m_live.contains(path); }
    QStringList livePaths() const { return m_live.keys(); }
    // A controllable live path forwards requestValue() to its service instead
    // of editing the snapshot; the UI changes only once publishLive() confirms.
    using LiveWriter = std::function<bool(const QVariant &)>;
    void setLiveWriter(const QString &path, const LiveWriter &writer);
  signals:
    void changed();
    void valueEdited(const QString &path);

  private:
    QVariantMap m_baseline;
    QVariantMap m_snapshot;
    QVariantMap m_live;
    QHash<QString, LiveWriter> m_writers;
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
