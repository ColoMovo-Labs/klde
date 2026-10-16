// SPDX-License-Identifier: GPL-3.0-or-later
#include "backends/BlurBackend.h"
#include "backends/MockSystemBackend.h"
#include "backends/MockWindowManagerBackend.h"
#include "models/ApplicationModel.h"
#include <QSignalSpy>
#include <QtTest>

class BackendTest final : public QObject {
    Q_OBJECT
  private slots:
    void quickSettingsClampAndRejectInvalidState() {
        klde::MockSystemBackend system;
        QSignalSpy osd(&system, &klde::SystemBackend::osdRequested);
        system.setVolume(150);
        QCOMPARE(system.volume(), 100);
        QCOMPARE(osd.count(), 1);
        system.setVolume(100);
        QCOMPARE(osd.count(), 1);
        system.setBrightness(-10);
        QCOMPARE(system.brightness(), 0);
        system.setPowerProfile(QStringLiteral("unknown"));
        QCOMPARE(system.powerProfile(), QStringLiteral("Balanced"));
        QVERIFY(!system.requestSessionAction(QStringLiteral("arbitrary-command")));
    }
    void searchAndActivationKeepStableApplicationIds() {
        klde::ApplicationModel apps;
        klde::ApplicationFilterModel search(&apps);
        search.setQuery(QStringLiteral("  TERMINAL  "));
        QCOMPARE(search.count(), 1);
        QCOMPARE(search.idAt(0), QStringLiteral("terminal"));
        QVERIFY(search.idAt(-1).isEmpty());
        QVERIFY(!apps.activate(QStringLiteral("unknown")));
        search.setQuery(QStringLiteral("no-such-application"));
        QCOMPARE(search.count(), 0);
    }
    void workspaceRequestsDoNotSilentlyAcceptUnsupportedOperations() {
        klde::MockWindowManagerBackend manager;
        QVERIFY(!manager.activateWorkspace(QStringLiteral("unknown")));
        QCOMPARE(manager.activeWorkspace(), QStringLiteral("workspace-1"));
        QVERIFY(manager.activateWorkspace(QStringLiteral("workspace-3")));
        QVERIFY(!manager.setWorkspaceLayout(QStringLiteral("workspace-3"),
                                            klde::WindowManagerBackend::Scrolling));
        QVERIFY(manager.setWindowFloating(QStringLiteral("demo-terminal"), false));
        QVERIFY(!manager.windows().first().toMap().value("floating").toBool());
    }
    void blurNeverClaimsUnownedContentSupport() {
        klde::PreviewBlurBackend blur;
        blur.setQuality(klde::BlurBackend::Medium);
        QCOMPARE(blur.strategyFor(true), klde::BlurBackend::OpaqueFallback);
        blur.setGraphicsAvailable(true);
        QCOMPARE(blur.strategyFor(true), klde::BlurBackend::OwnedContentGpu);
        QCOMPARE(blur.strategyFor(false), klde::BlurBackend::OpaqueFallback);
        blur.setRenderingAllowed(false);
        QCOMPARE(blur.strategyFor(true), klde::BlurBackend::OpaqueFallback);
        QVERIFY(!blur.nativeAvailable());
    }
};
QTEST_GUILESS_MAIN(BackendTest)
#include "test_backends.moc"
