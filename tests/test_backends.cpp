// SPDX-License-Identifier: GPL-3.0-or-later
#include "backends/BlurBackend.h"
#include "backends/KWinWindowManagerBackend.h"
#include "backends/MockSystemBackend.h"
#include "backends/MockWindowManagerBackend.h"
#include "backends/PresentationBackends.h"
#include "models/ApplicationModel.h"
#include "platform/common/SessionRuntimeBackend.h"
#include <QSignalSpy>
#include <QtTest>

namespace {
// Fixed window list for the dock overlap contract.
class FixedWindows final : public klde::WindowManagerBackend {
  public:
    QVariantList items;
    QVariantList workspaces() const override { return {}; }
    QVariantList windows() const override { return items; }
    QString activeWorkspace() const override { return QStringLiteral("one"); }
    QVariantMap capabilities() const override { return {}; }
    bool activateWorkspace(const QString &) override { return false; }
    bool setWorkspaceLayout(const QString &, LayoutMode) override { return false; }
    bool setWindowFloating(const QString &, bool) override { return false; }
    bool moveWindow(const QString &, const QString &) override { return false; }
    bool applyWindowRule(const klde::WindowRule &) override { return false; }
};
QVariantMap window(const QString &workspace, const QRectF &geometry, bool minimized = false) {
    return {{"workspaceId", workspace},
            {"workspaceIds", QStringList{workspace}},
            {"minimized", minimized},
            {"geometry", geometry.isValid() ? QVariant(geometry) : QVariant()}};
}
} // namespace

class BackendTest final : public QObject {
    Q_OBJECT
  private slots:
    void dockOverlapCountsOnlyVisibleWindowsOnTheActiveWorkspace() {
        FixedWindows manager;
        const QRectF dock(600, 1000, 400, 64);
        manager.items = {window("two", {0, 0, 1920, 1080}), window("one", {0, 0, 1920, 1080}, true),
                         window("one", {}), window("one", {100, 100, 800, 600})};
        QVERIFY(!manager.windowOverlaps(dock));
        manager.items.append(window("one", {500, 500, 600, 520}));
        QVERIFY(manager.windowOverlaps(dock));
        klde::MockWindowManagerBackend mock;
        QVERIFY(!mock.windowOverlaps(dock));
    }
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
    void disconnectedKwinAdapterNeverInventsWindowsOrAcceptsCallbacks() {
        klde::KWinWindowManagerBackend manager;
        QVERIFY(!manager.capabilities().value("mock").toBool());
        QVERIFY(!manager.capabilities().value("available").toBool());
        QVERIFY(manager.workspaces().isEmpty());
        QVERIFY(manager.windows().isEmpty());
        QVERIFY(!manager.snapshot("untrusted", "{\"schema\":1,\"sequence\":1}"));
        QVERIFY(!manager.activateWindow("made-up"));
        QVERIFY(!manager.activateWorkspace("workspace-1"));
        QVERIFY(!manager.moveWindow("made-up", "workspace-1"));
        QVERIFY(!manager.closeWindow("made-up"));
        manager.commandFinished("untrusted", "arbitrary-script", true);
        QVERIFY(manager.windows().isEmpty());
    }
    void sessionProbeReportsEnvironmentWithoutClaimingMockIntegration() {
        klde::SessionRuntimeBackend session;
        const auto capabilities = session.capabilities();
        QCOMPARE(capabilities.value("mock").toBool(), false);
        QCOMPARE(capabilities.value("wayland").toBool(), session.waylandSession());
        QCOMPARE(capabilities.value("kwinService").toBool(), session.kwinService());
        QVERIFY(!session.diagnostic().isEmpty());
    }
    void anOrdinaryPreviewCannotLogOutTheUser() {
        klde::SessionRuntimeBackend session;
        const QSignalSpy logout(&session, &klde::SessionRuntimeBackend::logoutRequested);
        QVERIFY(!session.managed());
        QVERIFY(!session.logout());
        QCOMPARE(logout.count(), 0);
    }
    void systemClockUsesCivilTimeWithoutInventingLocationOrWeather() {
        const auto before = QDateTime::fromString("2026-12-31T23:59:00+09:00", Qt::ISODate);
        const auto after = before.addSecs(60);
        const auto reading = klde::SystemTimeBackend::readingAt(before);
        QCOMPARE(reading.value("timeText").toString(), QString("23:59"));
        QCOMPARE(reading.value("dateTime").toString(), before.toString(Qt::ISODate));
        QCOMPARE(klde::SystemTimeBackend::readingAt(after).value("timeText").toString(),
                 QString("00:00"));
        QCOMPARE(after.date(), QDate(2027, 1, 1));
        QVERIFY(!reading.value("mock").toBool());
        QVERIFY(!reading.value("weatherAvailable").toBool());
        QVERIFY(!reading.value("astronomy").toMap().value("available").toBool());
        QCOMPARE(reading.value("season").toString(), QString("unavailable"));
        klde::SystemTimeBackend clock;
        const auto observed =
            QDateTime::fromString(clock.reading().value("dateTime").toString(), Qt::ISODate);
        QVERIFY(qAbs(observed.secsTo(QDateTime::currentDateTime())) <= 2);
    }
};
QTEST_GUILESS_MAIN(BackendTest)
#include "test_backends.moc"
