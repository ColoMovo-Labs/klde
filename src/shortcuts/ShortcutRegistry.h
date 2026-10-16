// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

namespace klde {
class ShortcutRegistry : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.shortcuts")
    Q_PROPERTY(QString launcher READ launcher NOTIFY bindingsChanged)
    Q_PROPERTY(QString quickSettings READ quickSettings NOTIFY bindingsChanged)
    Q_PROPERTY(QString blurLab READ blurLab NOTIFY bindingsChanged)
    Q_PROPERTY(QString reducedMotion READ reducedMotion NOTIFY bindingsChanged)
    Q_PROPERTY(QVariantList actions READ actions NOTIFY bindingsChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(bool globalAvailable READ globalAvailable CONSTANT)
  public:
    explicit ShortcutRegistry(QObject *parent = nullptr);
    QString launcher() const { return sequence(QStringLiteral("shell.launcher")); }
    QString quickSettings() const { return sequence(QStringLiteral("shell.quick-settings")); }
    QString blurLab() const { return sequence(QStringLiteral("preview.blur-lab")); }
    QString reducedMotion() const { return sequence(QStringLiteral("effects.reduced-motion")); }
    QVariantList actions() const;
    QString lastError() const { return m_lastError; }
    bool globalAvailable() const { return false; }
    Q_INVOKABLE QString sequence(const QString &actionId) const;
    Q_INVOKABLE bool rebind(const QString &actionId, const QString &portableSequence);
    Q_INVOKABLE void resetDefaults();
  signals:
    void bindingsChanged();
    void lastErrorChanged();

  private:
    struct Action {
        QString id;
        QString label;
        QString defaultSequence;
        QString sequence;
    };
    void setError(const QString &message);
    QList<Action> m_actions;
    QString m_lastError;
};
} // namespace klde
