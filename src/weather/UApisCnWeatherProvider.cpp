// SPDX-License-Identifier: GPL-3.0-or-later
#include "UApisCnWeatherProvider.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QNetworkRequest>
#include <QTimeZone>
#include <QUrlQuery>
#include <algorithm>
#include <cmath>
#include <utility>

namespace {
bool safeText(const QString &text, qsizetype maximum) {
  return !text.trimmed().isEmpty() && text.size() <= maximum &&
         std::all_of(text.cbegin(), text.cend(),
                     [](QChar c) { return c.isPrint(); });
}
std::optional<double> temperature(const QJsonValue &value) {
  if (!value.isDouble())
    return std::nullopt;
  const double result = value.toDouble();
  if (!std::isfinite(result) || result < -150 || result > 100)
    return std::nullopt;
  return result;
}
QDateTime retryTime(const QByteArray &header, const QDateTime &now) {
  bool numeric = false;
  const qint64 seconds = header.trimmed().toLongLong(&numeric);
  if (numeric && seconds >= 0) {
    const QDateTime result = now.addSecs(seconds);
    return result.isValid() ? result
                            : QDateTime(QDate(9999, 12, 31), QTime(23, 59, 59),
                                        QTimeZone::utc());
  }
  const QString value = QString::fromLatin1(header.trimmed());
  QDateTime result = QDateTime::fromString(value, Qt::RFC2822Date);
  if (!result.isValid()) {
    const QDateTime parsed =
        QLocale::c().toDateTime(value, "ddd, dd MMM yyyy HH:mm:ss 'GMT'");
    if (parsed.isValid())
      result = QDateTime(parsed.date(), parsed.time(), QTimeZone::utc());
  }
  return result.isValid() && result > now ? result.toUTC() : QDateTime();
}
} // namespace

namespace klde {
UApisCnWeatherProvider::UApisCnWeatherProvider(QObject *parent)
    : WeatherProvider(parent) {
  m_deadline.setSingleShot(true);
  m_deadline.setInterval(10000);
  connect(&m_deadline, &QTimer::timeout, this, [this] {
    cancel();
    emit failed({WeatherFailure::Kind::Unavailable,
                 tr("Weather request timed out"),
                 {}});
  });
}
UApisCnWeatherProvider::~UApisCnWeatherProvider() { cancel(); }

void UApisCnWeatherProvider::setNetworkConsent(bool enabled) {
  m_consent = enabled;
  if (!enabled)
    cancel();
}

QUrl UApisCnWeatherProvider::requestUrl(const WeatherQuery &query) {
  if (!query.valid())
    return {};
  QUrl url(QStringLiteral("https://uapis.cn/api/v1/misc/weather"));
  QUrlQuery parameters;
  parameters.addQueryItem(QStringLiteral("city"), query.city.trimmed());
  parameters.addQueryItem(QStringLiteral("lang"), query.language);
  url.setQuery(parameters);
  return url;
}

void UApisCnWeatherProvider::request(const WeatherQuery &query) {
  if (!m_consent) {
    emit failed({WeatherFailure::Kind::AccessDenied,
                 tr("Online weather is disabled"),
                 {}});
    return;
  }
  const QUrl url = requestUrl(query);
  if (url.isEmpty()) {
    emit failed({WeatherFailure::Kind::InvalidInput,
                 tr("Choose a city and language"),
                 {}});
    return;
  }
  if (busy() && m_query == query)
    return;
  cancel();
  m_query = query;
  QNetworkRequest request(url);
  request.setTransferTimeout(10000);
  request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                       QNetworkRequest::ManualRedirectPolicy);
  request.setAttribute(QNetworkRequest::CookieLoadControlAttribute,
                       QNetworkRequest::Manual);
  request.setAttribute(QNetworkRequest::CookieSaveControlAttribute,
                       QNetworkRequest::Manual);
  request.setAttribute(QNetworkRequest::AuthenticationReuseAttribute,
                       QNetworkRequest::Manual);
  request.setRawHeader("Accept", "application/json");
  request.setRawHeader("Accept-Encoding", "identity");
  request.setRawHeader("User-Agent", "KLDE-weather-preview/0.1");
  QNetworkReply *reply = m_network.get(request);
  m_reply = reply;
  reply->setReadBufferSize(MaximumResponseBytes + 1);
  connect(reply, &QNetworkReply::readyRead, this,
          [this, reply] { consume(reply); });
  connect(reply, &QNetworkReply::finished, this,
          [this, reply] { finish(reply); });
  m_deadline.start();
}

void UApisCnWeatherProvider::cancel() {
  m_deadline.stop();
  if (m_reply) {
    QNetworkReply *reply = m_reply.data();
    m_reply.clear();
    disconnect(reply, nullptr, this, nullptr);
    reply->abort();
    reply->deleteLater();
  }
  m_body.clear();
}

bool UApisCnWeatherProvider::consume(QNetworkReply *reply) {
  if (m_reply != reply)
    return false;
  m_body += reply->read(MaximumResponseBytes - m_body.size() + 1);
  if (m_body.size() > MaximumResponseBytes) {
    cancel();
    emit failed({WeatherFailure::Kind::InvalidResponse,
                 tr("Weather response is too large"),
                 {}});
    return false;
  }
  return true;
}

void UApisCnWeatherProvider::finish(QNetworkReply *reply) {
  if (!consume(reply))
    return;
  m_deadline.stop();
  m_reply.clear();
  const QByteArray body = std::exchange(m_body, {});
  const int status =
      reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
  const auto error = reply->error();
  const QByteArray retryAfter = reply->rawHeader("Retry-After");
  reply->deleteLater();
  if (status != 200) {
    emit failed(classifyFailure(status, body, QDateTime::currentDateTimeUtc(),
                                retryAfter));
    return;
  }
  if (error != QNetworkReply::NoError) {
    emit failed({WeatherFailure::Kind::Unavailable,
                 tr("Weather could not be downloaded"),
                 {}});
    return;
  }
  QString reason;
  const auto reading = parse(body, QDateTime::currentDateTimeUtc(), &reason);
  if (!reading) {
    emit failed({WeatherFailure::Kind::InvalidResponse, reason, {}});
    return;
  }
  emit ready(*reading);
}

std::optional<WeatherReading>
UApisCnWeatherProvider::parse(const QByteArray &body,
                              const QDateTime &fetchedAt, QString *error) {
  auto invalid = [error]() -> std::optional<WeatherReading> {
    if (error)
      *error =
          tr("Weather response is unavailable or has an unsupported format");
    return std::nullopt;
  };
  if (body.size() > MaximumResponseBytes)
    return invalid();
  QJsonParseError parseError;
  const QJsonDocument document = QJsonDocument::fromJson(body, &parseError);
  if (parseError.error != QJsonParseError::NoError || !document.isObject())
    return invalid();
  const QJsonObject object = document.object();
  const auto current = temperature(object.value("temperature"));
  const QString city = object.value("city").toString();
  const QString condition = object.value("weather").toString();
  if (!current || !safeText(city, 128) || !safeText(condition, 256))
    return invalid();
  WeatherReading result;
  result.location = city;
  result.condition = condition;
  result.temperature = *current;
  result.fetchedAt = fetchedAt.toUTC();
  result.high = temperature(object.value("temp_max"));
  result.low = temperature(object.value("temp_min"));
  if (result.high && result.low && *result.high < *result.low) {
    result.high.reset();
    result.low.reset();
  }
  for (const auto *key : {"weather_icon", "weather_code", "weathercode"}) {
    const QJsonValue value = object.value(QLatin1String(key));
    const QString icon = value.isString()   ? value.toString()
                         : value.isDouble() ? QString::number(value.toInt())
                                            : QString();
    if (safeText(icon, 16)) {
      result.iconCode = icon;
      break;
    }
  }
  const QString observed = object.value("report_time").toString();
  if (safeText(observed, 64))
    result.observedAt = observed; // The documented timestamp has no timezone;
                                  // do not invent one.
  if (error)
    error->clear();
  return result;
}

WeatherFailure
UApisCnWeatherProvider::classifyFailure(int httpStatus, const QByteArray &body,
                                        const QDateTime &now,
                                        const QByteArray &retryAfter) {
  const QJsonObject object =
      QJsonDocument::fromJson(body.left(MaximumResponseBytes)).object();
  QString code = object.value("code").toString();
  if (code.isEmpty())
    code = object.value("error").toString();
  if (code == "VISITOR_MONTHLY_QUOTA_EXHAUSTED")
    return {
        WeatherFailure::Kind::QuotaExhausted,
        tr("The weather provider's shared monthly visitor quota is exhausted"),
        {}};
  if (httpStatus == 429)
    return {WeatherFailure::Kind::RateLimited,
            tr("The weather provider requested a pause"),
            retryTime(retryAfter, now)};
  if (httpStatus == 400 || httpStatus == 404)
    return {WeatherFailure::Kind::InvalidInput,
            tr("No weather is available for that city"),
            {}};
  if (httpStatus >= 300 && httpStatus < 500)
    return {WeatherFailure::Kind::AccessDenied,
            tr("Weather access was refused; redirects and paid access are not "
               "enabled"),
            {}};
  return {WeatherFailure::Kind::Unavailable,
          tr("The weather provider is temporarily unavailable"),
          retryTime(retryAfter, now)};
}
} // namespace klde
