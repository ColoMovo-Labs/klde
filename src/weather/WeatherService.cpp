// SPDX-License-Identifier: GPL-3.0-or-later
#include "WeatherService.h"
#include <algorithm>
#include <limits>
#include <utility>

namespace {
constexpr int MinimumFetchSeconds = 15 * 60;
constexpr int ScheduledFetchSeconds = 2 * 60 * 60;
} // namespace

namespace klde {
WeatherService::WeatherService(QObject *parent)
    : WeatherService(nullptr, [] { return QDateTime::currentDateTimeUtc(); }, parent) {}

WeatherService::WeatherService(WeatherProvider *provider, Clock clock, QObject *parent)
    : QObject(parent), m_provider(provider ? provider : &m_uapis), m_clock(std::move(clock)) {
    m_schedule.setSingleShot(true);
    m_schedule.setTimerType(Qt::CoarseTimer);
    connect(&m_schedule, &QTimer::timeout, this, [this] {
        if (m_clock() < m_notBefore) {
            schedule(m_notBefore);
            return;
        }
        refresh();
    });
    connect(&m_mock, &WeatherProvider::ready, this, [this](const WeatherReading &reading) {
        if (!m_enabled) {
            m_reading = reading;
            emit changed();
        }
    });
    connect(m_provider, &WeatherProvider::ready, this, &WeatherService::received);
    connect(m_provider, &WeatherProvider::failed, this, &WeatherService::failed);
    m_provider->setNetworkConsent(false);
    m_mock.request({QStringLiteral("Snowline"), QStringLiteral("en")});
}

WeatherService::~WeatherService() {
    m_provider->setNetworkConsent(false);
    m_provider->cancel();
}

void WeatherService::applyPreview(const WeatherReading &reading, bool available) {
    disableOnline();
    m_reading = available ? std::optional<WeatherReading>{reading} : std::nullopt;
    m_query.city = reading.location;
    m_status = available ? QStringLiteral("mock") : QStringLiteral("unavailable");
    emit changed();
}
QVariantMap WeatherService::reading() const {
    QVariantMap result = m_reading ? m_reading->toVariantMap()
                                   : QVariantMap{{"location", m_query.city},
                                                 {"temperature", QVariant()},
                                                 {"condition", tr("Weather unavailable")},
                                                 {"available", false}};
    result.insert(QStringLiteral("sourceLabel"), attribution());
    result.insert(QStringLiteral("stale"), m_stale);
    result.insert(QStringLiteral("status"), m_status);
    return result;
}

QString WeatherService::attribution() const {
    if (!m_enabled)
        return tr("Mock weather");
    const QString provider = m_provider->id();
    return m_stale ? tr("%1 · cached").arg(provider) : tr("Weather via %1").arg(provider);
}

bool WeatherService::enableOnline(const QString &city, const QString &language) {
    const WeatherQuery query{city.trimmed(), language};
    if (!query.valid()) {
        m_message = tr("Choose a city and either English or Chinese weather");
        emit changed();
        return false;
    }
    if (!m_enabled || m_query != query) {
        m_schedule.stop();
        m_provider->cancel();
        m_reading.reset(); // Never show the previous city's weather under a new location.
        m_query = query;
        m_failures = 0;
        m_busy = false;
        m_stale = false;
        m_status = QStringLiteral("unavailable");
    }
    m_enabled = true;
    m_quotaBlocked =
        false; // Explicit re-enabling is the only retry after monthly quota exhaustion.
    m_provider->setNetworkConsent(true);
    refresh();
    return true;
}

void WeatherService::disableOnline() {
    m_schedule.stop();
    m_provider->setNetworkConsent(false);
    m_provider->cancel();
    m_enabled = false;
    m_busy = false;
    m_stale = false;
    m_quotaBlocked = false;
    m_failures = 0;
    m_status = QStringLiteral("mock");
    m_message.clear();
    m_query = {};
    m_mock.request({QStringLiteral("Snowline"), QStringLiteral("en")});
    // Retain the in-process cooldown so toggling consent cannot create a request burst.
}

bool WeatherService::refresh() {
    if (!m_enabled || m_busy || m_quotaBlocked)
        return false;
    const QDateTime now = m_clock();
    if (m_notBefore.isValid() && now < m_notBefore) {
        m_message = tr("Weather refresh is paused to respect the provider's limits");
        if (!m_schedule.isActive())
            schedule(m_notBefore);
        emit changed();
        return false;
    }
    m_schedule.stop();
    m_busy = true;
    m_status = QStringLiteral("loading");
    m_message.clear();
    if (m_reading && m_reading->fetchedAt.secsTo(now) >= ScheduledFetchSeconds)
        m_stale = true;
    m_notBefore = now.addSecs(MinimumFetchSeconds);
    emit changed();
    m_provider->request(m_query);
    return true;
}

void WeatherService::received(const WeatherReading &reading) {
    if (!m_enabled)
        return;
    m_reading = reading;
    m_reading->fetchedAt = m_clock();
    m_busy = false;
    m_stale = false;
    m_failures = 0;
    m_status = QStringLiteral("ready");
    m_message.clear();
    schedule(m_clock().addSecs(ScheduledFetchSeconds));
    emit changed();
}

void WeatherService::failed(const WeatherFailure &failure) {
    if (!m_enabled)
        return;
    m_busy = false;
    m_stale = m_reading.has_value();
    m_message = failure.message;
    m_schedule.stop();
    if (failure.kind == WeatherFailure::Kind::QuotaExhausted) {
        m_quotaBlocked = true;
        m_status = QStringLiteral("quota-exhausted");
    } else if (failure.retryable()) {
        m_status = failure.kind == WeatherFailure::Kind::RateLimited
                       ? QStringLiteral("rate-limited")
                       : QStringLiteral("unavailable");
        const int exponent = std::min(m_failures, 3);
        m_failures = std::min(m_failures + 1, 4);
        const QDateTime backoff = m_clock().addSecs(MinimumFetchSeconds * (qint64{1} << exponent));
        m_notBefore = std::max(m_notBefore, backoff);
        if (failure.retryAt.isValid())
            m_notBefore = std::max(m_notBefore, failure.retryAt);
        schedule(m_notBefore);
    } else {
        m_status = QStringLiteral("unavailable");
    }
    emit changed();
}

void WeatherService::schedule(const QDateTime &at) {
    if (!m_enabled || m_quotaBlocked)
        return;
    // QTimer's int interval is bounded. Long Retry-After values re-arm without fetching early.
    const qint64 milliseconds = std::max<qint64>(1, m_clock().msecsTo(at));
    m_schedule.start(
        static_cast<int>(std::min<qint64>(milliseconds, std::numeric_limits<int>::max())));
}
} // namespace klde
