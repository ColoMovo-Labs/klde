// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include "backends/BlurBackend.h"
#include "backends/SystemBackend.h"
#include <QVariantList>

namespace klde {
class PowerSceneController : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.scenes")
    Q_PROPERTY(QVariantList scenes READ scenes NOTIFY scenesChanged)
    Q_PROPERTY(QString activeId READ activeId NOTIFY currentChanged)
    Q_PROPERTY(QVariantMap current READ current NOTIFY currentChanged)
    Q_PROPERTY(QVariantMap capabilities READ capabilities CONSTANT)
  public:
    PowerSceneController(SystemBackend *system, BlurBackend *blur, QObject *parent = nullptr);
    QVariantList scenes() const { return m_scenes; }
    QString activeId() const;
    QVariantMap current() const;
    QVariantMap capabilities() const;
    Q_INVOKABLE bool select(const QString &id);
    Q_INVOKABLE bool customize(const QString &option, const QVariant &value);
    Q_INVOKABLE void resetCurrent();
    void resetDefaults();
  signals:
    void scenesChanged();
    void currentChanged();
    void requestRejected(const QString &reason);

  private:
    static QVariantList defaults();
    void apply();
    SystemBackend *m_system;
    BlurBackend *m_blur;
    QVariantList m_scenes;
    qsizetype m_active = 1;
};
} // namespace klde
