// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "mock/SystemStateModel.h"
#include <QDateTime>
#include <QFileSystemWatcher>
#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

namespace klde {
class TimeBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.time")
    Q_PROPERTY(QVariantMap reading READ reading NOTIFY changed)
  public:
    using QObject::QObject;
    virtual QVariantMap reading() const = 0;
  signals:
    void changed();
};
class MockTimeBackend final : public TimeBackend {
    Q_OBJECT
  public:
    explicit MockTimeBackend(SystemStateModel *state);
    QVariantMap reading() const override;

  private:
    SystemStateModel *m_state;
};
class SystemTimeBackend final : public TimeBackend {
    Q_OBJECT
  public:
    explicit SystemTimeBackend(QObject *parent = nullptr);
    QVariantMap reading() const override { return m_reading; }
    static QVariantMap readingAt(const QDateTime &date);
    void refresh();

  private:
    QVariantMap m_reading;
    QTimer m_minute;
    QFileSystemWatcher m_zone;
};
class TelemetryBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.telemetry")
    Q_PROPERTY(QVariantList cells READ cells NOTIFY changed)
  public:
    using QObject::QObject;
    virtual QVariantList cells() const = 0;
  signals:
    void changed();
};
class MockTelemetryBackend final : public TelemetryBackend {
    Q_OBJECT
  public:
    explicit MockTelemetryBackend(SystemStateModel *state);
    QVariantList cells() const override;

  private:
    SystemStateModel *m_state;
};
class WallpaperEffectsBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.wallpaperEffects")
    Q_PROPERTY(QVariantMap state READ state NOTIFY changed)
  public:
    using QObject::QObject;
    virtual QVariantMap state() const = 0;
    Q_INVOKABLE virtual bool regeneratePreview() = 0;
    Q_INVOKABLE virtual void clearPreview() = 0;
  signals:
    void changed();
};
class MockWallpaperEffectsBackend final : public WallpaperEffectsBackend {
    Q_OBJECT
  public:
    explicit MockWallpaperEffectsBackend(SystemStateModel *state);
    QVariantMap state() const override;
    bool regeneratePreview() override;
    void clearPreview() override;

  private:
    SystemStateModel *m_state;
};
class WaydroidBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.waydroid")
    Q_PROPERTY(QVariantMap state READ state NOTIFY changed)
  public:
    using QObject::QObject;
    virtual QVariantMap state() const = 0;
    Q_INVOKABLE virtual bool setRunning(bool running) = 0;
  signals:
    void changed();
};
class MockWaydroidBackend final : public WaydroidBackend {
    Q_OBJECT
  public:
    explicit MockWaydroidBackend(SystemStateModel *state);
    QVariantMap state() const override;
    bool setRunning(bool running) override;

  private:
    SystemStateModel *m_state;
};
} // namespace klde
