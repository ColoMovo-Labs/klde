// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

namespace klde {
class InputMethodBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.input")
    Q_PROPERTY(bool engineAvailable READ engineAvailable NOTIFY changed)
    Q_PROPERTY(bool simulated READ simulated CONSTANT)
    Q_PROPERTY(bool switchingSupported READ switchingSupported CONSTANT)
    Q_PROPERTY(QString currentId READ currentId NOTIFY changed)
    Q_PROPERTY(QString indicator READ indicator NOTIFY changed)
    Q_PROPERTY(QVariantList methods READ methods CONSTANT)
  public:
    using QObject::QObject;
    virtual bool engineAvailable() const = 0;
    virtual bool simulated() const = 0;
    virtual bool switchingSupported() const = 0;
    virtual QString currentId() const = 0;
    virtual QString indicator() const = 0;
    virtual QVariantList methods() const = 0;
    Q_INVOKABLE virtual bool requestSwitch(const QString &id) = 0;
    Q_INVOKABLE virtual bool selectPreview(const QString &id) = 0;
  signals:
    void changed();
};
} // namespace klde
