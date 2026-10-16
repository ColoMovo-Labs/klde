// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "MockWeatherProvider.h"
#include "UApisCnWeatherProvider.h"
#include <QtQml/qqmlregistration.h>
#include <functional>

namespace klde {
// A single configured city with an in-memory cache. Construction never starts network activity.
class WeatherService : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.weatherService")
    Q_PROPERTY(QVariantMap reading READ reading NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(bool onlineEnabled READ onlineEnabled NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(bool stale READ stale NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(QString attribution READ attribution NOTIFY changed)
    Q_PROPERTY(QDateTime nextAllowedFetch READ nextAllowedFetch NOTIFY changed)
  public:
    using Clock = std::function<QDateTime()>;
    explicit WeatherService(QObject *parent = nullptr);
    ~WeatherService() override;
    // Injected provider/clock support deterministic offline CI. The provider must outlive this
    // service.
    WeatherService(WeatherProvider *provider, Clock clock, QObject *parent = nullptr);
    QVariantMap reading() const;
    QString status() const { return m_status; }
    bool onlineEnabled() const { return m_enabled; }
    bool busy() const { return m_busy; }
    bool stale() const { return m_stale; }
    QString message() const { return m_message; }
    QString attribution() const;
    QDateTime nextAllowedFetch() const { return m_notBefore; }

    // The caller must first disclose provider terms, location/IP disclosure and the experimental
    // status.
    Q_INVOKABLE bool enableOnline(const QString &city,
                                  const QString &language = QStringLiteral("en"));
    Q_INVOKABLE void disableOnline();
    Q_INVOKABLE bool refresh();
  signals:
    void changed();

  private:
    void received(const WeatherReading &reading);
    void failed(const WeatherFailure &failure);
    void schedule(const QDateTime &at);
    MockWeatherProvider m_mock;
    UApisCnWeatherProvider m_uapis;
    WeatherProvider *m_provider;
    Clock m_clock;
    QTimer m_schedule;
    WeatherQuery m_query;
    std::optional<WeatherReading> m_reading;
    QDateTime m_notBefore;
    QString m_status = QStringLiteral("mock");
    QString m_message;
    int m_failures = 0;
    bool m_enabled = false;
    bool m_busy = false;
    bool m_stale = false;
    bool m_quotaBlocked = false;
};
} // namespace klde
