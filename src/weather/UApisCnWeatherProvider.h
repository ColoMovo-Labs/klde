// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "WeatherProvider.h"
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QPointer>
#include <QTimer>
#include <QUrl>

namespace klde {
// Experimental visitor access only. No API keys, automatic location lookup or redirects.
class UApisCnWeatherProvider final : public WeatherProvider {
    Q_OBJECT
  public:
    explicit UApisCnWeatherProvider(QObject *parent = nullptr);
    ~UApisCnWeatherProvider() override;
    QString id() const override { return QStringLiteral("uapis.cn"); }
    void setNetworkConsent(bool enabled) override;
    void request(const WeatherQuery &query) override;
    void cancel() override;
    bool busy() const { return !m_reply.isNull(); }

    static constexpr qsizetype MaximumResponseBytes = qsizetype{256} * 1024;
    static QUrl requestUrl(const WeatherQuery &query);
    static std::optional<WeatherReading> parse(const QByteArray &body, const QDateTime &fetchedAt,
                                               QString *error = nullptr);
    static WeatherFailure classifyFailure(int httpStatus, const QByteArray &body,
                                          const QByteArray &retryAfter, const QDateTime &now);

  private:
    bool consume(QNetworkReply *reply);
    void finish(QNetworkReply *reply);
    QNetworkAccessManager m_network;
    QPointer<QNetworkReply> m_reply;
    QTimer m_deadline;
    QByteArray m_body;
    WeatherQuery m_query;
    bool m_consent = false;
};
} // namespace klde
