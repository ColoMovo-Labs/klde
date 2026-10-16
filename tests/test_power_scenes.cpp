// SPDX-License-Identifier: GPL-3.0-or-later
#include "backends/MockSystemBackend.h"
#include "models/PowerSceneController.h"
#include <QtTest>

class PowerSceneTest final : public QObject {
    Q_OBJECT
  private slots:
    void presetsRetainBlurAndRejectUnsupportedHardware() {
        klde::MockSystemBackend system;
        klde::PreviewBlurBackend blur;
        klde::PowerSceneController scenes(&system, &blur);
        QCOMPARE(scenes.activeId(), QStringLiteral("balanced"));
        QCOMPARE(blur.quality(), klde::BlurBackend::Medium);
        QVERIFY(scenes.select(QStringLiteral("performance")));
        QCOMPARE(blur.quality(), klde::BlurBackend::Low);
        QCOMPARE(system.powerProfile(), QStringLiteral("Performance"));
        QVERIFY(scenes.select(QStringLiteral("power-saver")));
        QCOMPARE(blur.quality(), klde::BlurBackend::Low);
        QVERIFY(!scenes.capabilities().value("discreteGpu").toBool());
        QVERIFY(!scenes.customize(QStringLiteral("cpuFrequency"), 3000));
        QVERIFY(!scenes.select(QStringLiteral("unknown")));
    }
    void customizationIsValidatedIndependentAndResettable() {
        klde::MockSystemBackend system;
        klde::PreviewBlurBackend blur;
        klde::PowerSceneController scenes(&system, &blur);
        QVERIFY(!scenes.customize(QStringLiteral("blurQuality"), 7));
        QVERIFY(!scenes.customize(QStringLiteral("motion"), 1.5));
        QVERIFY(!scenes.customize(QStringLiteral("motion"), true));
        QVERIFY(!scenes.customize(QStringLiteral("blurQuality"), QStringLiteral("2")));
        QVERIFY(!scenes.customize(QStringLiteral("theme"), QStringLiteral("remote.qml")));
        QVERIFY(!scenes.customize(QStringLiteral("blurEnabled"), QStringLiteral("false")));
        QVERIFY(scenes.customize(QStringLiteral("blurEnabled"), false));
        QCOMPARE(blur.quality(), klde::BlurBackend::Off);
        QVERIFY(scenes.current().value("customized").toBool());
        QVERIFY(scenes.select(QStringLiteral("performance")));
        QVERIFY(!scenes.current().value("customized").toBool());
        QVERIFY(scenes.select(QStringLiteral("balanced")));
        QCOMPARE(blur.quality(), klde::BlurBackend::Off);
        scenes.resetCurrent();
        QCOMPARE(blur.quality(), klde::BlurBackend::Medium);
        QVERIFY(!scenes.current().value("customized").toBool());
    }
};
QTEST_GUILESS_MAIN(PowerSceneTest)
#include "test_power_scenes.moc"
