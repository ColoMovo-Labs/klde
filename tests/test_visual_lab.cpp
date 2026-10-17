// SPDX-License-Identifier: GPL-3.0-or-later
#include "mock/SystemStateModel.h"
#include "models/NotificationModel.h"
#include "status/StatusModuleRegistry.h"
#include <QSignalSpy>
#include <QtTest>
class VisualLabTest final : public QObject {
    Q_OBJECT
  private slots:
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
        QVERIFY(modules.move(QStringLiteral("cpu"), -1));
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
