// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QFont>
#include <QImageReader>
#include <QQmlApplicationEngine>
#include <QQuickItem>
#include <QQuickWindow>
#include <QRawFont>
#include <QSignalSpy>
#include <QtQml/QQmlExtensionPlugin>
#include <QtTest>

Q_IMPORT_QML_PLUGIN(KldeShellPlugin)
Q_IMPORT_QML_PLUGIN(KldeBackendsPlugin)

class ShellStartupTest final : public QObject {
    Q_OBJECT
  private slots:
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
        QVERIFY(window->title().contains(QStringLiteral("LoMoDE")));
        QVERIFY(window->findChild<QObject *>(QStringLiteral("statusLabel")) != nullptr);
        QCoreApplication::processEvents();
        auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
        auto *tokens = engine.singletonInstance<QObject *>("KLDE.Shell", "Tokens");
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
