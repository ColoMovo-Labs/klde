// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QDateTime>
#include <QObject>
#include <QVariantMap>
#include <optional>

namespace klde {
enum class WeatherCondition : quint8 {
    Clear,
    PartlyCloudy,
    Cloudy,
    Rain,
    Snow,
    Thunderstorm,
    Fog,
    Unknown
};
WeatherCondition normalizeWeatherCondition(const QString &description);
struct WeatherQuery {
    QString city;
    QString language = QStringLiteral("en");
    bool operator==(const WeatherQuery &) const = default;
    bool valid() const;
};

struct WeatherReading {
    WeatherCondition category = WeatherCondition::Unknown;
    QString location;
    QString condition;
    QString iconCode;
    QString observedAt;
    double temperature = 0;
    std::optional<double> high;
    std::optional<double> low;
    QDateTime fetchedAt;
    QVariantMap toVariantMap() const;
    QString conditionId() const;
};

struct WeatherFailure {
    enum class Kind : quint8 {
        InvalidInput,
        InvalidResponse,
        Unavailable,
        RateLimited,
        QuotaExhausted,
        AccessDenied
    };
    Kind kind = Kind::Unavailable;
    QString message;
    QDateTime retryAt;
    bool retryable() const { return kind == Kind::Unavailable || kind == Kind::RateLimited; }
};

// Providers normalize data; scheduling, presentation state and consent live in WeatherService.
// cancel() must suppress subsequent results for the canceled request.
class WeatherProvider : public QObject {
    Q_OBJECT
  public:
    using QObject::QObject;
    virtual QString id() const = 0;
    virtual void setNetworkConsent(bool enabled) = 0;
    virtual void request(const WeatherQuery &query) = 0;
    virtual void cancel() = 0;
  signals:
    void ready(const klde::WeatherReading &reading);
    void failed(const klde::WeatherFailure &failure);
};
} // namespace klde

Q_DECLARE_METATYPE(klde::WeatherReading)
Q_DECLARE_METATYPE(klde::WeatherFailure)
