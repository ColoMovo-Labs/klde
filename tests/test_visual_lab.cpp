// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include "mock/SystemStateModel.h"
#include "models/NotificationModel.h"
#include "status/StatusModuleRegistry.h"
#include <QSignalSpy>
#include <QtTest>
class VisualLabTest final : public QObject {
    Q_OBJECT
  private slots:
    void temporalCacheAndOptionalAppContracts() {
        klde::ShellServices shell(nullptr);
        QVERIFY(shell.mockScenarios()->apply("starry-night"));
        QCOMPARE(shell.time()->reading().value("phase").toString(), QStringLiteral("starry-night"));
        QCOMPARE(shell.time()->reading().value("season").toString(), QStringLiteral("winter"));
        QVERIFY(!shell.time()->reading().value("moonVisible").toBool());
        QVERIFY(shell.time()->reading().value("astronomy").toMap().value("simulated").toBool());
        QVERIFY(shell.state()->advanceMinutes(1));
        QCOMPARE(shell.time()->reading().value("timeText").toString(), QStringLiteral("22:21"));
        QVERIFY(shell.mockScenarios()->apply("wallpaper-depth-enabled"));
        QCOMPARE(shell.wallpaperEffects()->state().value("effectiveMode").toString(),
                 QStringLiteral("depth"));
        QVERIFY(shell.state()->requestValue("powerScene", QStringLiteral("power-saver")));
        QCOMPARE(shell.wallpaperEffects()->state().value("effectiveMode").toString(),
                 QStringLiteral("normal"));
        QCOMPARE(shell.state()->value("wallpaperEffects.mode").toString(), QStringLiteral("depth"));
        QVERIFY(shell.state()->requestValue("powerScene", QStringLiteral("balanced")));
        QCOMPARE(shell.wallpaperEffects()->state().value("effectiveMode").toString(),
                 QStringLiteral("depth"));
        QVERIFY(shell.state()->requestValue("appearance.wallpaper", QStringLiteral("abstract")));
        QVERIFY(!shell.wallpaperEffects()->state().value("cacheValid").toBool());
        QVERIFY(!shell.wallpaperEffects()->regeneratePreview());
        QVERIFY(shell.wallpaperEffects()->state().value("foregroundAsset").toString().isEmpty());
        QVERIFY(shell.mockScenarios()->apply("segmentation-failed"));
        QCOMPARE(shell.wallpaperEffects()->state().value("effectiveMode").toString(),
                 QStringLiteral("normal"));
        QVERIFY(!shell.state()->requestValue("wallpaperEffects.blurStrength", 4));
        QVERIFY(!shell.waydroid()->setRunning(true));
        const int linuxApps = shell.applications()->rowCount();
        QVERIFY(shell.mockScenarios()->apply("waydroid-ready"));
        QCOMPARE(shell.applications()->rowCount(), linuxApps + 1);
        QCOMPARE(
            shell.applications()
                ->data(shell.applications()->index(linuxApps), klde::ApplicationModel::OriginRole)
                .toString(),
            QStringLiteral("android"));
        QVERIFY(shell.launch(QStringLiteral("android-sketch")));
        QVERIFY(shell.waydroid()->setRunning(false));
        QVERIFY(!shell.launch(QStringLiteral("android-sketch")));
        QVERIFY(shell.state()->requestValue("waydroid.available", false));
        QCOMPARE(shell.applications()->rowCount(), linuxApps);
        QCOMPARE(shell.applications()->activeId(), QStringLiteral("desktop"));
    }
    void temporalAutoPhaseFollowsWeatherLayer() {
        klde::ShellServices shell(nullptr);
        QVERIFY(
            shell.state()->requestValue(QStringLiteral("temporal.phase"), QStringLiteral("auto")));
        QVERIFY(shell.state()->requestValue(QStringLiteral("time"),
                                            QStringLiteral("2026-07-10T14:30:00")));
        QVERIFY(shell.state()->requestValue(QStringLiteral("weather.condition"),
                                            QStringLiteral("rain")));
        QCOMPARE(shell.time()->reading().value("phase").toString(),
                 QStringLiteral("rainy-evening"));
        QVERIFY(shell.state()->requestValue(QStringLiteral("weather.condition"),
                                            QStringLiteral("snow")));
        QCOMPARE(shell.time()->reading().value("phase").toString(),
                 QStringLiteral("rainy-evening"));
        QVERIFY(shell.state()->requestValue(QStringLiteral("weather.condition"),
                                            QStringLiteral("fog")));
        QCOMPARE(shell.time()->reading().value("phase").toString(), QStringLiteral("cloudy-day"));
        QVERIFY(shell.state()->requestValue(QStringLiteral("weather.condition"),
                                            QStringLiteral("clear")));
        QCOMPARE(shell.time()->reading().value("phase").toString(), QStringLiteral("cloudy-day"));
    }
    void scenarioProjectionAndEditsStayCoherent() {
        klde::ShellServices shell(nullptr);
        QVERIFY(shell.mockScenarios()->apply("offline"));
        QVERIFY(!shell.system()->wifi());
        shell.system()->setWifi(true);
        QVERIFY(shell.state()->value("network.connected").toBool());
        QVERIFY(shell.state()->requestValue("audio.volume", 31));
        QCOMPARE(shell.system()->volume(), 31);
        shell.system()->setVolume(46);
        QCOMPARE(shell.state()->value("audio.volume").toInt(), 46);
        QVERIFY(shell.mockScenarios()->apply("critical-battery"));
        QCOMPARE(shell.state()->alerts().value("battery").toInt(), 2);
        shell.notifications()->clearAll();
        QCOMPARE(shell.state()->value("notifications.count").toInt(), 0);
        QVERIFY(shell.mockScenarios()->apply("hybrid-gpu-laptop"));
        QVERIFY(shell.scenes()->select("performance"));
        QCOMPARE(shell.state()->value("policy.gpu").toString(), QStringLiteral("hybrid"));
        QCOMPARE(shell.state()->value("policy.refreshRate").toInt(), 120);
        QVERIFY(shell.scenes()->select("power-saver"));
        QCOMPARE(shell.state()->value("policy.frequency").toInt(), 55);
        QVERIFY(shell.mockScenarios()->apply("dark-night"));
        QCOMPARE(shell.scenes()->current().value("visual").toMap().value("theme").toString(),
                 QStringLiteral("dark"));
        QVERIFY(shell.mockScenarios()->apply("laptop-balanced"));
        QCOMPARE(shell.state()->alerts().value("battery").toInt(), 0);
        QVERIFY(shell.state()->requestValue("input.currentId", QStringLiteral("pinyin")));
        QCOMPARE(shell.input()->currentId(), QStringLiteral("pinyin"));
    }

    void scenariosAreCompleteAndResettable() {
        klde::SystemStateModel state;
        klde::MockScenarioManager scenarios(&state);
        QVERIFY(state.ready());
        QVERIFY(scenarios.scenarios().size() >= 20);
        for (const auto &item : scenarios.scenarios()) {
            QVERIFY2(scenarios.apply(item.toMap().value("id").toString()),
                     qPrintable(item.toMap().value("id").toString()));
            QVERIFY(state.value("network.connected").isValid());
            QVERIFY(state.value("media.progress").isValid());
        }
        QVERIFY(scenarios.apply(QStringLiteral("critical-battery")));
        QCOMPARE(state.value("battery.percent").toInt(), 4);
        QVERIFY(scenarios.apply(QStringLiteral("laptop-balanced")));
        QCOMPARE(state.value("battery.percent").toInt(), 74);
        const auto before = state.snapshot();
        QVERIFY(!scenarios.apply(QStringLiteral("unknown")));
        QCOMPARE(state.snapshot(), before);
    }
    void controlsValidateTypesAndCapabilities() {
        klde::SystemStateModel state;
        klde::MockScenarioManager scenarios(&state);
        QVERIFY(!state.requestValue(QStringLiteral("cpu.usage"), true));
        QVERIFY(!state.requestValue(QStringLiteral("cpu.usage"), 101));
        QVERIFY(!state.requestValue(QStringLiteral("cpu.usage"), 10.5));
        QVERIFY(!state.requestValue(QStringLiteral("locale"), QStringLiteral("zh_CN_cute")));
        QVERIFY(!state.requestValue(QStringLiteral("appearance.wallpaper"),
                                    QStringLiteral("https://invalid.example/image")));
        QVERIFY(scenarios.apply(QStringLiteral("desktop-no-battery")));
        QVERIFY(!state.requestValue(QStringLiteral("battery.percent"), 40));
        QVERIFY(!state.requestValue(QStringLiteral("brightness"), 40));
        QVERIFY(scenarios.apply(QStringLiteral("hybrid-gpu-laptop")));
        QVERIFY(state.requestValue(QStringLiteral("policy.gpu"), QStringLiteral("discrete")));
        auto incomplete = state.snapshot();
        incomplete.remove("network");
        QVERIFY(!state.replacePreview(incomplete));
        QCOMPARE(state.value("policy.gpu").toString(), QStringLiteral("discrete"));
        QVERIFY(state.advanceMinutes(1));
        QVERIFY(state.value("time").toString().contains("08:31"));
    }
    void notificationActionsAndModuleCustomization() {
        klde::NotificationModel notifications;
        notifications.seedDemo(3, QStringLiteral("battery"));
        QCOMPARE(notifications.count(), 3);
        QVERIFY(notifications.data(notifications.index(0), klde::NotificationModel::TitleRole)
                    .toString()
                    .startsWith("critical."));
        QVERIFY(notifications.dismiss(QStringLiteral("fixture-0")));
        QCOMPARE(notifications.count(), 2);
        notifications.clearAll();
        QCOMPARE(notifications.count(), 0);
        klde::StatusModuleRegistry modules;
        QCOMPARE(modules.modules().size(), 20);
        QVERIFY(modules.setSection(QStringLiteral("cpu"), 0));
        QVERIFY(modules.setSection(QStringLiteral("memory"), 0));
        QVERIFY(modules.move(QStringLiteral("memory"), -1));
        QVERIFY(!modules.setSection(QStringLiteral("cpu"), 1));
        QVERIFY(!modules.setVisible(QStringLiteral("time"), false));
        QVERIFY(!modules.setSection(QStringLiteral("cpu"), 5));
        QVERIFY(!modules.setVisible(QStringLiteral("unknown"), false));
        modules.setMargin(-1);
        QCOMPARE(modules.margin(), 4);
        modules.reset();
        QCOMPARE(modules.margin(), 16);
    }
};
QTEST_GUILESS_MAIN(VisualLabTest)
#include "test_visual_lab.moc"
