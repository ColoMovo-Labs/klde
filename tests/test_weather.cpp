// SPDX-License-Identifier: GPL-3.0-or-later
#include "weather/UApisCnWeatherProvider.h"
#include "weather/WeatherService.h"
#include <QSignalSpy>
#include <QUrlQuery>
#include <QtTest>

namespace {
// Synthetic fixtures, not redistributed observations from the provider.
const QByteArray Fixture =
    R"({"city":"Fixture Harbour","weather":"Passing cloud",
    "temperature":7.25,"weather_icon":"101","report_time":"2030-01-02 03:04:05"})";

class FakeWeatherProvider final : public klde::WeatherProvider {
  public:
    using WeatherProvider::WeatherProvider;
    QString id() const override { return QStringLiteral("fixture"); }
    void setNetworkConsent(bool enabled) override { consent = enabled; }
    void request(const klde::WeatherQuery &query) override {
        if (consent) {
            ++requests;
            lastQuery = query;
        }
    }
    void cancel() override { ++cancellations; }
    void succeed(const QDateTime &now) {
        emit ready(*klde::UApisCnWeatherProvider::parse(Fixture, now));
    }
    void reject(klde::WeatherFailure::Kind kind, const QDateTime &retryAt = {}) {
        emit failed({kind, QStringLiteral("Synthetic provider failure"), retryAt});
    }
    int requests = 0;
    int cancellations = 0;
    bool consent = false;
    klde::WeatherQuery lastQuery;
};
} // namespace

class WeatherTest final : public QObject {
    Q_OBJECT
  private slots:
    void queryRequiresExplicitLocationAndSupportedLanguage() {
        using Provider = klde::UApisCnWeatherProvider;
        QVERIFY(Provider::requestUrl({QString(), QStringLiteral("en")}).isEmpty());
        QVERIFY(Provider::requestUrl({QStringLiteral("\n"), QStringLiteral("en")}).isEmpty());
        QVERIFY(Provider::requestUrl({QStringLiteral("City"), QStringLiteral("fr")}).isEmpty());
        const QUrl url =
            Provider::requestUrl({QStringLiteral("海岸 & Harbour"), QStringLiteral("zh")});
        QCOMPARE(url.scheme(), QStringLiteral("https"));
        QCOMPARE(url.host(), QStringLiteral("uapis.cn"));
        QCOMPARE(url.path(), QStringLiteral("/api/v1/misc/weather"));
        const QUrlQuery query(url);
        QCOMPARE(query.queryItemValue(QStringLiteral("city"), QUrl::FullyDecoded),
                 QStringLiteral("海岸 & Harbour"));
        QCOMPARE(query.queryItems().size(), 2);
    }
    void parserPreservesUnknownConditionAndOptionalFields() {
        using Provider = klde::UApisCnWeatherProvider;
        const QDateTime now =
            QDateTime::fromString(QStringLiteral("2030-01-02T04:05:06Z"), Qt::ISODate);
        QString error;
        auto reading = Provider::parse(Fixture, now, &error);
        QVERIFY(reading.has_value());
        QVERIFY(error.isEmpty());
        QCOMPARE(reading->temperature, 7.25);
        QCOMPARE(reading->location, QStringLiteral("Fixture Harbour"));
        QCOMPARE(reading->condition, QStringLiteral("Passing cloud"));
        QCOMPARE(reading->observedAt, QStringLiteral("2030-01-02 03:04:05"));
        QCOMPARE(reading->fetchedAt, now);
        QVERIFY(!reading->high.has_value());
        QVERIFY(!reading->low.has_value());
        QVERIFY(!reading->toVariantMap().value("high").isValid());
        QByteArray variant = Fixture;
        variant.replace("weather_icon", "weather_code");
        variant.replace("\"101\"", "\"unknown-new-icon\"");
        reading = Provider::parse(variant, now);
        QVERIFY(reading.has_value());
        QCOMPARE(reading->iconCode, QStringLiteral("unknown-new-icon"));
    }
    void parserRejectsBrokenRequiredFields_data() {
        QTest::addColumn<QByteArray>("body");
        QTest::newRow("invalid-json") << QByteArray("<html>unavailable</html>");
        QTest::newRow("array") << QByteArray("[]");
        QTest::newRow("missing") << QByteArray("{\"city\":\"Here\",\"weather\":\"Clear\"}");
        QTest::newRow("string-number")
            << QByteArray("{\"city\":\"Here\",\"weather\":\"Clear\",\"temperature\":\"12\"}");
        QTest::newRow("null-number")
            << QByteArray("{\"city\":\"Here\",\"weather\":\"Clear\",\"temperature\":null}");
        QTest::newRow("wrong-unit-or-outlier")
            << QByteArray("{\"city\":\"Here\",\"weather\":\"Clear\",\"temperature\":10000}");
        QTest::newRow("overlong") << QByteArray(
            klde::UApisCnWeatherProvider::MaximumResponseBytes + 1, ' ');
    }
    void parserRejectsBrokenRequiredFields() {
        QFETCH(QByteArray, body);
        QString error;
        QVERIFY(
            !klde::UApisCnWeatherProvider::parse(body, QDateTime::currentDateTimeUtc(), &error));
        QVERIFY(!error.isEmpty());
    }
    void adapterNeverStartsWithoutConsent() {
        klde::UApisCnWeatherProvider provider;
        QSignalSpy rejected(&provider, &klde::WeatherProvider::failed);
        provider.request({QStringLiteral("Fixture Harbour"), QStringLiteral("en")});
        QCOMPARE(rejected.count(), 1);
        QVERIFY(!provider.busy());
        const auto failure = qvariant_cast<klde::WeatherFailure>(rejected.takeFirst().at(0));
        QCOMPARE(failure.kind, klde::WeatherFailure::Kind::AccessDenied);
    }
    void errorsDistinguishMonthlyQuotaAndHonorRetryAfter() {
        using Provider = klde::UApisCnWeatherProvider;
        using Kind = klde::WeatherFailure::Kind;
        const QDateTime now =
            QDateTime::fromString(QStringLiteral("2030-01-02T04:05:06Z"), Qt::ISODate);
        auto failure = Provider::classifyFailure(
            429, R"({"error":"VISITOR_MONTHLY_QUOTA_EXHAUSTED"})", now, "30");
        QCOMPARE(failure.kind, Kind::QuotaExhausted);
        QVERIFY(!failure.retryable());
        failure = Provider::classifyFailure(429, R"({"code":429})", now, "86400");
        QCOMPARE(failure.kind, Kind::RateLimited);
        QCOMPARE(failure.retryAt, now.addDays(1));
        failure = Provider::classifyFailure(503, "{}", now, "Wed, 02 Jan 2030 05:05:06 GMT");
        QCOMPARE(failure.retryAt, now.addSecs(3600));
        QVERIFY(failure.retryable());
        failure = Provider::classifyFailure(302, "", now, "");
        QCOMPARE(failure.kind, Kind::AccessDenied);
        QVERIFY(!failure.retryable());
    }
    void serviceUsesMockUntilConsentAndDeduplicatesRequests() {
        FakeWeatherProvider provider;
        QDateTime now = QDateTime::fromString(QStringLiteral("2030-01-02T04:05:06Z"), Qt::ISODate);
        klde::WeatherService service(&provider, [&now] { return now; });
        QVERIFY(!service.onlineEnabled());
        QCOMPARE(service.status(), QStringLiteral("mock"));
        QCOMPARE(service.reading().value("location").toString(), QStringLiteral("Snowline"));
        QVERIFY(!service.refresh());
        QVERIFY(!service.enableOnline(QString(), QStringLiteral("en")));
        QCOMPARE(provider.requests, 0);
        QVERIFY(service.enableOnline(QStringLiteral("Fixture Harbour"), QStringLiteral("en")));
        QVERIFY(provider.consent);
        QCOMPARE(provider.requests, 1);
        QVERIFY(service.busy());
        QVERIFY(!service.refresh());
        QVERIFY(service.enableOnline(QStringLiteral("Fixture Harbour"), QStringLiteral("en")));
        QCOMPARE(provider.requests, 1);
        provider.succeed(now);
        QVERIFY(!service.busy());
        QCOMPARE(service.status(), QStringLiteral("ready"));
        QVERIFY(!service.refresh());
        QCOMPARE(provider.requests, 1);
        service.disableOnline();
        QVERIFY(!provider.consent);
        QCOMPARE(service.status(), QStringLiteral("mock"));
        QCOMPARE(service.reading().value("location").toString(), QStringLiteral("Snowline"));
        QVERIFY(service.enableOnline(QStringLiteral("Another Harbour"), QStringLiteral("en")));
        QCOMPARE(provider.requests,
                 1); // Consent/city changes cannot bypass the global cooldown.
        QVERIFY(!service.reading().value("available").toBool());
    }
    void serviceKeepsStaleDataAndStopsOnQuotaExhaustion() {
        using Kind = klde::WeatherFailure::Kind;
        FakeWeatherProvider provider;
        QDateTime now = QDateTime::fromString(QStringLiteral("2030-01-02T04:05:06Z"), Qt::ISODate);
        klde::WeatherService service(&provider, [&now] { return now; });
        service.enableOnline(QStringLiteral("Fixture Harbour"));
        provider.succeed(now);
        now = now.addSecs(16 * 60);
        QVERIFY(service.refresh());
        provider.reject(Kind::Unavailable);
        QVERIFY(service.stale());
        QCOMPARE(service.reading().value("temperature").toDouble(), 7.25);
        QVERIFY(!service.refresh());
        now = now.addSecs(16 * 60);
        QVERIFY(service.refresh());
        provider.reject(Kind::QuotaExhausted);
        QCOMPARE(service.status(), QStringLiteral("quota-exhausted"));
        const int requests = provider.requests;
        now = now.addDays(35);
        QVERIFY(!service.refresh());
        QCOMPARE(provider.requests, requests);
    }
    void serviceHonorsLongProviderPauseAndRevokesConsentOnDestruction() {
        FakeWeatherProvider provider;
        QDateTime now = QDateTime::fromString(QStringLiteral("2030-01-02T04:05:06Z"), Qt::ISODate);
        {
            klde::WeatherService service(&provider, [&now] { return now; });
            service.enableOnline(QStringLiteral("Fixture Harbour"));
            provider.reject(klde::WeatherFailure::Kind::RateLimited, now.addDays(2));
            QCOMPARE(service.nextAllowedFetch(), now.addDays(2));
            now = now.addDays(1);
            QVERIFY(!service.refresh());
            QCOMPARE(provider.requests, 1);
        }
        QVERIFY(!provider.consent);
        QVERIFY(provider.cancellations > 0);
    }
};

QTEST_GUILESS_MAIN(WeatherTest)
#include "test_weather.moc"
