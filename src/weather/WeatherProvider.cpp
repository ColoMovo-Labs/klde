// SPDX-License-Identifier: GPL-3.0-or-later
#include "WeatherProvider.h"
#include <algorithm>

namespace klde {
WeatherCondition normalizeWeatherCondition(const QString &description) {
    const auto value = description.trimmed().toCaseFolded();
    if (value == "clear" || value == "sunny" || value == "晴")
        return WeatherCondition::Clear;
    if (value == "partly cloudy" || value == "clouds & sunshine" || value == "晴间多云")
        return WeatherCondition::PartlyCloudy;
    if (value == "cloudy" || value == "overcast" || value == "多云" || value == "阴")
        return WeatherCondition::Cloudy;
    if (value == "rain" || value == "light rain" || value == "雨" || value == "小雨")
        return WeatherCondition::Rain;
    if (value == "snow" || value == "雪" || value == "小雪")
        return WeatherCondition::Snow;
    if (value == "thunderstorm" || value == "雷雨" || value == "雷阵雨")
        return WeatherCondition::Thunderstorm;
    if (value == "fog" || value == "mist" || value == "雾")
        return WeatherCondition::Fog;
    return WeatherCondition::Unknown;
}
QString WeatherReading::conditionId() const {
    switch (category) {
    case WeatherCondition::Clear:
        return QStringLiteral("weather.condition.clear");
    case WeatherCondition::PartlyCloudy:
        return QStringLiteral("weather.condition.partly-cloudy");
    case WeatherCondition::Cloudy:
        return QStringLiteral("weather.condition.cloudy");
    case WeatherCondition::Rain:
        return QStringLiteral("weather.condition.rain");
    case WeatherCondition::Snow:
        return QStringLiteral("weather.condition.snow");
    case WeatherCondition::Thunderstorm:
        return QStringLiteral("weather.condition.thunderstorm");
    case WeatherCondition::Fog:
        return QStringLiteral("weather.condition.fog");
    case WeatherCondition::Unknown:
        return QStringLiteral("weather.condition.unknown");
    }
    return QStringLiteral("weather.condition.unknown");
}
bool WeatherQuery::valid() const {
    return !city.trimmed().isEmpty() && city.size() <= 128 &&
           std::all_of(city.cbegin(), city.cend(), [](QChar c) { return c.isPrint(); }) &&
           (language == "en" || language == "zh");
}

QVariantMap WeatherReading::toVariantMap() const {
    return {{"location", location},
            {"condition", condition},
            {"conditionId", conditionId()},
            {"iconCode", iconCode},
            {"observedAt", observedAt},
            {"temperature", temperature},
            {"high", high ? QVariant(*high) : QVariant()},
            {"low", low ? QVariant(*low) : QVariant()},
            {"fetchedAt", fetchedAt},
            {"available", true}};
}
} // namespace klde
