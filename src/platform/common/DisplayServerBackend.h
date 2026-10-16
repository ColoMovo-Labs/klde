// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

namespace klde {
class DisplayServerBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.displayServer")
    Q_PROPERTY(QString platform READ platform CONSTANT)
    Q_PROPERTY(QString protocol READ protocol CONSTANT)
    Q_PROPERTY(QVariantMap capabilities READ capabilities CONSTANT)
  public:
    using QObject::QObject;
    QString platform() const;
    QString protocol() const;
    QVariantMap capabilities() const;
};
} // namespace klde
