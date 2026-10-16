// SPDX-License-Identifier: GPL-3.0-or-later
#include "WeatherProvider.h"
#include <algorithm>

namespace klde {
bool WeatherQuery::valid() const {
    return !city.trimmed().isEmpty() && city.size() <= 128 &&
           std::all_of(city.cbegin(), city.cend(), [](QChar c) { return c.isPrint(); }) &&
           (language == "en" || language == "zh");
}

QVariantMap WeatherReading::toVariantMap() const {
    return {{"location", location},
            {"condition", condition},
            {"iconCode", iconCode},
            {"observedAt", observedAt},
            {"temperature", temperature},
            {"high", high ? QVariant(*high) : QVariant()},
            {"low", low ? QVariant(*low) : QVariant()},
            {"fetchedAt", fetchedAt},
            {"available", true}};
}
} // namespace klde
