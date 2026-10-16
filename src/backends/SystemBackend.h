// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QtQml/qqmlregistration.h>

namespace klde {
class SystemBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.system")
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY stateChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY stateChanged)
    Q_PROPERTY(bool wifi READ wifi WRITE setWifi NOTIFY stateChanged)
    Q_PROPERTY(bool bluetooth READ bluetooth WRITE setBluetooth NOTIFY stateChanged)
    Q_PROPERTY(bool nightMode READ nightMode WRITE setNightMode NOTIFY stateChanged)
    Q_PROPERTY(QString powerProfile READ powerProfile WRITE setPowerProfile NOTIFY stateChanged)
    Q_PROPERTY(bool mock READ mock CONSTANT)
  public:
    using QObject::QObject;
    virtual int volume() const = 0;
    virtual int brightness() const = 0;
    virtual bool wifi() const = 0;
    virtual bool bluetooth() const = 0;
    virtual bool nightMode() const = 0;
    virtual QString powerProfile() const = 0;
    virtual bool mock() const = 0;
    virtual void setVolume(int value) = 0;
    virtual void setBrightness(int value) = 0;
    virtual void setWifi(bool value) = 0;
    virtual void setBluetooth(bool value) = 0;
    virtual void setNightMode(bool value) = 0;
    virtual void setPowerProfile(const QString &profile) = 0;
    Q_INVOKABLE virtual bool requestSessionAction(const QString &action) = 0;
  signals:
    void stateChanged();
    void osdRequested(const QString &kind, int value);
    void actionReported(const QString &message);
    void requestRejected(const QString &reason);
};
} // namespace klde
