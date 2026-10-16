// SPDX-License-Identifier: GPL-3.0-or-later
#include "MockWeatherProvider.h"

namespace klde {
void MockWeatherProvider::request(const WeatherQuery &query) {
    if (!query.valid()) {
        emit failed({WeatherFailure::Kind::InvalidInput, tr("Choose a city and language"), {}});
        return;
    }
    WeatherReading reading;
    reading.location = QStringLiteral("Snowline");
    reading.condition = tr("Clouds & sunshine");
    reading.iconCode = QStringLiteral("101");
    reading.temperature = 18;
    reading.high = 21;
    reading.low = 12;
    emit ready(reading);
}
} // namespace klde
