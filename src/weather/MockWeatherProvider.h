// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "WeatherProvider.h"

namespace klde {
class MockWeatherProvider final : public WeatherProvider {
    Q_OBJECT
  public:
    using WeatherProvider::WeatherProvider;
    QString id() const override { return QStringLiteral("mock"); }
    void setNetworkConsent(bool) override {}
    void request(const WeatherQuery &query) override;
    void cancel() override {}
};
} // namespace klde
