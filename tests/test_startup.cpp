// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QFont>
#include <QImageReader>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickWindow>
#include <QRawFont>
#include <QScopeGuard>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtQml/QQmlExtensionPlugin>
#include <QtTest>

Q_IMPORT_QML_PLUGIN(KldeShellPlugin)
Q_IMPORT_QML_PLUGIN(KldeBackendsPlugin)

class ShellStartupTest final : public QObject {
    Q_OBJECT
  private slots:
    void realNativeTimeAdvancesWithoutRestart() {
        if (qEnvironmentVariableIntValue("OWODE_CLOUD_CLOCK_TEST") != 1)
            QSKIP("The real minute-wait integration check is cloud-only and opt-in");
        QTemporaryDir config;
        const auto previousConfig = qgetenv("XDG_CONFIG_HOME");
        qputenv("XDG_CONFIG_HOME", config.path().toUtf8());
        const auto restoreConfig = qScopeGuard([previousConfig] {
            if (previousConfig.isNull())
                qunsetenv("XDG_CONFIG_HOME");
            else
                qputenv("XDG_CONFIG_HOME", previousConfig);
        });
        QQmlEngine engine;
        engine.setProperty("owodeSystemApplications", true);
        QQmlComponent component(&engine);
        component.setData("import QtQuick\nimport KLDE.Shell\nSystemIsland {}", QUrl());
        QScopedPointer<QObject> island(component.create());
        QVERIFY2(island, qPrintable(component.errorString()));
        auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
        QVERIFY(qobject_cast<klde::SystemTimeBackend *>(services->time()));
        auto *text = island->findChild<QObject *>(QStringLiteral("temporalTimeText"));
        QVERIFY(text);
        const auto before = text->property("text").toString();
        QCOMPARE(before, services->time()->reading().value("timeText").toString());
        QTRY_VERIFY_WITH_TIMEOUT(text->property("text").toString() != before, 65000);
        QCOMPARE(text->property("text").toString(),
                 services->time()->reading().value("timeText").toString());
        QVERIFY(!services->time()->reading().value("mock").toBool());
        qInfo() << "Real native clock advanced" << before << "to" << text->property("text");
    }
    void weatherViewsFollowTheServiceInsteadOfFixtureState() {
        QQmlEngine engine;
        QQmlComponent component(&engine);
        component.setData("import QtQuick\nimport KLDE.Shell\nStatusModule { module: ({id: "
                          "'weather', titleId: 'lab.module.weather', icon: 'weather'}) }",
                          QUrl());
        QScopedPointer<QObject> status(component.create());
        QVERIFY2(status, qPrintable(component.errorString()));
        auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
        services->language()->setLocale(QStringLiteral("en"));
        klde::WeatherReading result;
        result.location = QStringLiteral("Service fixture");
        result.temperature = 7.25;
        result.condition = QStringLiteral("Clear");
        result.category = klde::WeatherCondition::Clear;
        services->weatherService()->applyPreview(result, true);
        QCOMPARE(services->state()->value("weather.temperature").toInt(), 21);
        QTRY_COMPARE(status->property("valueText").toString(), QString("7°"));
        QCOMPARE(status->property("iconName").toString(), QString("weather-clear"));
    }
    void temporalTextFollowsAnActualMinuteTimer() {
        auto now = QDateTime::fromString("2026-11-01T10:59:59.980+08:00", Qt::ISODateWithMs);
        klde::SystemTimeBackend clock([&now] { return now; });
        QQmlEngine engine;
        engine.rootContext()->setContextProperty(QStringLiteral("liveClock"), &clock);
        QQmlComponent component(&engine);
        component.setData("import QtQuick\nimport KLDE.Shell\nTemporalCapsule { readingOverride: "
                          "liveClock.reading }",
                          QUrl());
        QScopedPointer<QObject> capsule(component.create());
        QVERIFY2(capsule, qPrintable(component.errorString()));
        auto *text = capsule->findChild<QObject *>(QStringLiteral("temporalTimeText"));
        QVERIFY(text);
        QCOMPARE(text->property("text").toString(), QString("10:59"));
        now = now.addMSecs(20);
        QTRY_COMPARE(text->property("text").toString(), QString("11:00"));
    }
    void loadsPackagedModuleWithoutQmlWarnings() {
        QVERIFY2(QImageReader::supportedImageFormats().contains("svg"),
                 "The Qt SVG image plugin is required (Ubuntu: qt6-svg-plugins)");
        QQmlApplicationEngine engine;
        const QSignalSpy warnings(&engine, &QQmlApplicationEngine::warnings);
        engine.loadFromModule(QStringLiteral("KLDE.Shell"), QStringLiteral("Main"));
        QCOMPARE(engine.rootObjects().size(), 1);
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        QVERIFY(window != nullptr);
        QVERIFY(window->isVisible());
        QVERIFY(window->title().contains(QStringLiteral("owoDE")));
        // The corner "preview · mock services" caption is gone; mock data is
        // marked next to its control and summarized in Settings > About.
        QVERIFY(window->findChild<QObject *>(QStringLiteral("statusLabel")) == nullptr);
        QCoreApplication::processEvents();
        auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
        auto *tokens = engine.singletonInstance<QObject *>("Owo.Visuals", "Tokens");
        QVERIFY(services != nullptr && tokens != nullptr);
        QVERIFY(services->language()->setLocale(QStringLiteral("zh_CN")));
        QTRY_VERIFY(window->title().contains(QStringLiteral("桌面外壳")));
        QVERIFY(QRawFont::fromFont(QFont(QStringLiteral("Noto Sans CJK SC")))
                    .supportsCharacter(0x4e2dU));
        auto *center = window->findChild<QQuickItem *>(QStringLiteral("ribbonCenter"));
        QVERIFY(center != nullptr);
        const auto centerPoint =
            center->mapToScene(QPointF(center->width() / 2, center->height() / 2));
        QVERIFY(qAbs(centerPoint.x() - window->width() / 2.0) <= 1.0);
        QTest::mouseClick(
            window, Qt::LeftButton, Qt::NoModifier,
            center->mapToScene(QPointF(center->width() / 2, center->height() / 2)).toPoint());
        auto *detail = window->findChild<QObject *>(QStringLiteral("temporalDetail"));
        QVERIFY(detail != nullptr);
        QTRY_VERIFY(detail->property("opened").toBool());
        QVERIFY(QMetaObject::invokeMethod(detail, "close"));
        auto *clockLayer = window->findChild<QObject *>(QStringLiteral("desktopClockLayer"));
        QVERIFY(clockLayer != nullptr);
        QVERIFY(!clockLayer->property("visible").toBool());
        QVERIFY(services->state()->requestValue("appearance.ambient", true));
        QTRY_VERIFY(clockLayer->property("visible").toBool());
        QVERIFY(services->state()->requestValue("appearance.ambient", false));
        QTRY_VERIFY(!clockLayer->property("visible").toBool());
        QVERIFY(services->scenes()->select(QStringLiteral("power-saver")));
        QTRY_COMPARE(tokens->property("reducedMotion").toBool(), true);
        QVERIFY(services->scenes()->select(QStringLiteral("performance")));
        QTRY_COMPARE(tokens->property("reducedMotion").toBool(), false);
        QVERIFY(services->scenes()->customize(QStringLiteral("theme"), QStringLiteral("dark")));
        QTRY_COMPARE(tokens->property("darkMode").toBool(), true);
        QVERIFY(services->scenes()->customize(QStringLiteral("blurEnabled"), false));
        QCOMPARE(services->blur()->quality(), klde::BlurBackend::Off);
        QVERIFY(services->language()->setVoice(QStringLiteral("cute")));
        QVERIFY(!services->displayServer()->capabilities().value("sessionHost").toBool());
        QCOMPARE(warnings.count(), 0);
        window->close();
    }
};

QTEST_MAIN(ShellStartupTest)
#include "test_startup.moc"
