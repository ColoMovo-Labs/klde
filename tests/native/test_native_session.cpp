// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include "fake-input-client-protocol.h"
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQuickItem>
#include <QQuickWindow>
#include <QScopeGuard>
#include <QScreen>
#include <QSignalSpy>
#include <QtQml/QQmlExtensionPlugin>
#include <QtTest>
#include <algorithm>
#include <linux/input-event-codes.h>
#include <wayland-client.h>

Q_IMPORT_QML_PLUGIN(KldeShellPlugin)
Q_IMPORT_QML_PLUGIN(KldeBackendsPlugin)

namespace {
class Input final {
  public:
    Input() {
        m_display = wl_display_connect(nullptr);
        if (!m_display)
            return;
        m_registry = wl_display_get_registry(m_display);
        static const wl_registry_listener listener{global, removed};
        wl_registry_add_listener(m_registry, &listener, this);
        wl_display_roundtrip(m_display);
        if (m_input) {
            org_kde_kwin_fake_input_authenticate(m_input, "owoDE cloud native test",
                                                 "Isolated test compositor only");
            wl_display_roundtrip(m_display);
        }
    }
    ~Input() {
        if (m_input)
            wl_proxy_destroy(reinterpret_cast<wl_proxy *>(m_input));
        if (m_registry)
            wl_registry_destroy(m_registry);
        if (m_display)
            wl_display_disconnect(m_display);
    }
    bool valid() const { return m_input != nullptr; }
    void move(QPoint point) {
        org_kde_kwin_fake_input_pointer_motion_absolute(m_input, wl_fixed_from_int(point.x()),
                                                        wl_fixed_from_int(point.y()));
        sync();
    }
    void button(bool pressed) {
        org_kde_kwin_fake_input_button(m_input, BTN_LEFT,
                                       pressed ? WL_POINTER_BUTTON_STATE_PRESSED
                                               : WL_POINTER_BUTTON_STATE_RELEASED);
        sync();
    }
    void click(QPoint point) {
        move(point);
        button(true);
        button(false);
    }
    void key(uint32_t code, bool pressed) {
        org_kde_kwin_fake_input_keyboard_key(m_input, code,
                                             pressed ? WL_KEYBOARD_KEY_STATE_PRESSED
                                                     : WL_KEYBOARD_KEY_STATE_RELEASED);
        sync();
    }
    void key(uint32_t code) {
        key(code, true);
        key(code, false);
    }

  private:
    static void global(void *data, wl_registry *registry, uint32_t name, const char *interface,
                       uint32_t version) {
        auto *self = static_cast<Input *>(data);
        if (QByteArray(interface) == org_kde_kwin_fake_input_interface.name && version >= 4)
            self->m_input = static_cast<org_kde_kwin_fake_input *>(wl_registry_bind(
                registry, name, &org_kde_kwin_fake_input_interface, std::min(version, 6U)));
    }
    static void removed(void *, wl_registry *, uint32_t) {}
    void sync() { wl_display_roundtrip(m_display); }
    wl_display *m_display = nullptr;
    wl_registry *m_registry = nullptr;
    org_kde_kwin_fake_input *m_input = nullptr;
};

QQuickItem *findItem(QQuickItem *root, const QString &name) {
    if (root->objectName() == name)
        return root;
    for (auto *child : root->childItems())
        if (auto *match = findItem(child, name))
            return match;
    return nullptr;
}
QQuickWindow *findWindow(const QString &name) {
    for (auto *window : QGuiApplication::allWindows())
        if (window->objectName() == name)
            return qobject_cast<QQuickWindow *>(window);
    return nullptr;
}
QJsonObject readObject(const QString &path) {
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? QJsonDocument::fromJson(file.readAll()).object()
                                          : QJsonObject();
}
} // namespace

class NativeSessionTest final : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.owode.NativeAudit")
  public slots:
    void report(const QString &json) {
        m_windows = QJsonDocument::fromJson(json.toUtf8()).array();
        m_received = true;
    }

  private:
    bool snapshot(const QString &action = {}) {
        m_received = false;
        const auto name = QStringLiteral("owode-native-audit-%1").arg(++m_script);
        const auto path = m_output + "/" + name + ".js";
        QFile file(path);
        if (!file.open(QIODevice::WriteOnly))
            return false;
        const auto script = QStringLiteral(R"JS(
const windows = workspace.windowList();
const client = windows.find(w => w.caption === 'owoDE native CI application');
const action = '%1';
if (client && action === 'maximize') client.setMaximize(true, true);
if (client && action === 'place') {
    client.setMaximize(false, false);
    client.frameGeometry = {x: 500, y: -60, width: 480, height: 420};
}
if (client && action === 'close') client.closeWindow();
callDBus('org.owode.NativeAudit', '/Audit', 'org.owode.NativeAudit', 'report', JSON.stringify(windows.map(w => ({
    caption: w.caption, resourceClass: w.resourceClass, desktop: w.desktopWindow, dock: w.dock,
    normal: w.normalWindow, active: w.active,
    geometry: {x: w.frameGeometry.x, y: w.frameGeometry.y, width: w.frameGeometry.width, height: w.frameGeometry.height}
}))));
)JS")
                                .arg(action);
        file.write(script.toUtf8());
        file.close();
        QDBusInterface scripting("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting");
        const QDBusReply<int> loaded = scripting.call("loadScript", path, name);
        if (!loaded.isValid() || loaded.value() < 0)
            return false;
        QDBusInterface runner("org.kde.KWin", "/Scripting/Script" + QString::number(loaded.value()),
                              "org.kde.kwin.Script");
        const auto reply = runner.call("run");
        if (reply.type() == QDBusMessage::ErrorMessage)
            return false;
        QElapsedTimer timer;
        timer.start();
        while (!m_received && timer.elapsed() < 3000)
            QTest::qWait(10);
        scripting.call("unloadScript", name);
        if (m_received) {
            QFile audit(m_output + "/snapshot-" + QString::number(m_script) + ".json");
            if (audit.open(QIODevice::WriteOnly))
                audit.write(QJsonDocument(m_windows).toJson());
        }
        return m_received;
    }
    QJsonObject client() const {
        for (const auto &entry : m_windows)
            if (entry.toObject().value("caption") == "owoDE native CI application")
                return entry.toObject();
        return {};
    }
    bool capture(const QString &name) const {
        return QProcess::execute(QCoreApplication::applicationDirPath() + "/owode-native-capture",
                                 {m_output + "/" + name + ".png"}) == 0;
    }
    QString m_output;
    QJsonArray m_windows;
    int m_script = 0;
    bool m_received = false;

  private slots:
    void nativeSurfacesAndRealClient() {
        QVERIFY2(qEnvironmentVariable("OWODE_NATIVE_TEST_ISOLATED") == "1" &&
                     qEnvironmentVariable("WAYLAND_DISPLAY") == "owode-ci" &&
                     qEnvironmentVariable("XDG_RUNTIME_DIR")
                         .startsWith(QDir::tempPath() + "/owode-native-ci-"),
                 "Run only through tools/native-session-smoke.sh; never against a host session");
        QCOMPARE(QGuiApplication::platformName(), QString("wayland"));
        m_output = qEnvironmentVariable("OWODE_NATIVE_EVIDENCE");
        QVERIFY(!m_output.isEmpty());
        auto bus = QDBusConnection::sessionBus();
        QVERIFY(bus.registerService("org.owode.NativeAudit"));
        QVERIFY(bus.registerObject("/Audit", this, QDBusConnection::ExportAllSlots));
        QDBusInterface kwin("org.kde.KWin", "/KWin", "org.kde.KWin");
        const QDBusReply<QString> support = kwin.call("supportInformation");
        QVERIFY(support.isValid());
        QFile supportFile(m_output + "/kwin-support.txt");
        QVERIFY(supportFile.open(QIODevice::WriteOnly));
        supportFile.write(support.value().toUtf8());
        supportFile.close();
        Input input;
        QVERIFY2(input.valid(), "KWin's test input protocol must be advertised");
        QQmlApplicationEngine engine;
        QSignalSpy warnings(&engine, &QQmlApplicationEngine::warnings);
        engine.setInitialProperties({{"nativeSurfaceMode", true}, {"initialLocale", "en"}});
        engine.loadFromModule("KLDE.Shell", "Main");
        QCOMPARE(engine.rootObjects().size(), 1);
        auto *root = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        QVERIFY(root && !root->isVisible());
        auto *wallpaper = findWindow("nativeWallpaperSurface");
        auto *ribbon = findWindow("nativeRibbonSurface");
        auto *dock = findWindow("nativeDockSurface");
        auto *popup = findWindow("nativePopupSurface");
        QVERIFY(wallpaper && ribbon && dock && popup);
        QTRY_VERIFY(wallpaper->isExposed() && ribbon->isExposed() && dock->isExposed());
        const auto screen = wallpaper->screen()->geometry().size();
        QTRY_COMPARE(wallpaper->size(), screen);
        QTRY_COMPARE(ribbon->width(), screen.width());
        QTRY_VERIFY(!dock->mask().isEmpty() && !ribbon->mask().isEmpty());
        QVERIFY(!dock->mask().contains(QPoint(4, dock->height() / 2)));
        QVERIFY(!popup->isVisible());
        QVERIFY(snapshot());
        bool desktop = false;
        for (const auto &entry : m_windows) {
            const auto object = entry.toObject();
            if (object.value("desktop").toBool()) {
                const auto geometry = object.value("geometry").toObject();
                QCOMPARE(geometry.value("x").toInt(), 0);
                QCOMPARE(geometry.value("y").toInt(), 0);
                QCOMPARE(geometry.value("width").toInt(), screen.width());
                QCOMPARE(geometry.value("height").toInt(), screen.height());
                QVERIFY(!object.value("normal").toBool());
                desktop = true;
            }
        }
        QVERIFY2(desktop, "KWin must identify the wallpaper as a desktop window");
        QVERIFY(capture("native-background"));

        QProcess application;
        application.setProcessChannelMode(QProcess::ForwardedChannels);
        const auto statePath = m_output + "/client-state.json";
        application.start(QCoreApplication::applicationDirPath() + "/owode-native-test-client",
                          {"--state", statePath});
        QVERIFY(application.waitForStarted());
        QTRY_VERIFY(!readObject(statePath).isEmpty());
        // QWidget Show/state-file creation can precede KWin mapping the surface,
        // especially while a target host starts its private portal services.
        // Wait for the compositor-observed client before issuing its action.
        QTRY_VERIFY(snapshot() && client().value("normal").toBool());
        QVERIFY(snapshot("maximize"));
        QTRY_VERIFY(snapshot() &&
                    client().value("geometry").toObject().value("width").toInt() == screen.width());
        QVERIFY(client().value("normal").toBool());
        auto geometry = client().value("geometry").toObject();
        QCOMPARE(geometry.value("x").toInt(), 0);
        QCOMPARE(geometry.value("width").toInt(), screen.width());
        QVERIFY(geometry.value("y").toInt() >= ribbon->height());
        QVERIFY(qAbs(geometry.value("y").toInt() + geometry.value("height").toInt() -
                     screen.height()) <= 1);
        QVERIFY(capture("native-maximized"));
        // The transparent part of a full-width dock window must pass clicks to
        // the real maximized application behind it.
        auto clicks = readObject(statePath).value("clicks").toInt();
        input.click(QPoint(80, screen.height() - 60));
        QTRY_VERIFY(readObject(statePath).value("clicks").toInt() > clicks);

        auto *launcherButton = findItem(dock->contentItem(), "launcherButton");
        QVERIFY(launcherButton);
        const auto dockPoint = launcherButton->mapToScene(
            QPointF(launcherButton->width() / 2, launcherButton->height() / 2));
        input.click(QPoint(qRound(dockPoint.x()),
                           screen.height() - dock->height() + qRound(dockPoint.y())));
        auto *launcher = root->findChild<QObject *>("launcher");
        QVERIFY(launcher);
        QTRY_VERIFY(popup->isExposed() && launcher->property("opened").toBool());
        auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
        QVERIFY(services);
        for (const auto key : {KEY_T, KEY_E, KEY_R, KEY_M, KEY_I, KEY_N, KEY_A, KEY_L})
            input.key(static_cast<uint32_t>(key));
        QTRY_COMPARE(services->search()->query(), QString("terminal"));
        QTRY_VERIFY(!readObject(statePath).value("active").toBool());
        QTest::qWait(400);
        QVERIFY(capture("native-launcher"));
        input.key(KEY_ESC);
        QTRY_VERIFY(!popup->isVisible());
        QTRY_VERIFY(readObject(statePath).value("active").toBool());

        auto *wifi = findItem(ribbon->contentItem(), "statusModule-network");
        QVERIFY(wifi);
        const auto wifiPoint = wifi->mapToScene(QPointF(wifi->width() / 2, wifi->height() / 2));
        input.click(wifiPoint.toPoint());
        auto *settings = root->findChild<QObject *>("quickSettings");
        QVERIFY(settings);
        QTRY_VERIFY(settings->property("opened").toBool() && popup->isExposed());
        QTest::qWait(400);
        QVERIFY(capture("native-quick-settings"));
        input.click(QPoint(screen.width() / 2, screen.height() / 2));
        QTRY_VERIFY(!popup->isVisible());
        QTRY_VERIFY(readObject(statePath).value("active").toBool());

        QVERIFY(snapshot("place"));
        QTest::qWait(300);
        QVERIFY(snapshot());
        geometry = client().value("geometry").toObject();
        const QPoint original(geometry.value("x").toInt(), geometry.value("y").toInt());
        int gap = -1;
        for (int x = original.x() + 20; x < original.x() + 400; ++x) {
            if (!ribbon->mask().contains(QPoint(x, 40))) {
                gap = x;
                break;
            }
        }
        QVERIFY(gap >= 0);
        clicks = readObject(statePath).value("clicks").toInt();
        input.click(QPoint(gap, 40));
        QTRY_VERIFY(readObject(statePath).value("clicks").toInt() > clicks);
        // A normal modifier-drag goes through KWin input, not a synthetic move
        // on the Qt client. The runner configures Meta+left only in its own rc.
        const QPoint start(original.x() + 200, std::max(160, original.y() + 200));
        input.move(start);
        input.key(KEY_LEFTMETA, true);
        input.button(true);
        input.move(start + QPoint(80, 70));
        QTest::qWait(100);
        input.button(false);
        input.key(KEY_LEFTMETA, false);
        QTest::qWait(300);
        QVERIFY(snapshot());
        geometry = client().value("geometry").toObject();
        QVERIFY(geometry.value("x").toInt() != original.x() ||
                geometry.value("y").toInt() != original.y());
        QVERIFY(capture("native-floating"));
        QVERIFY(snapshot("close"));
        QTRY_COMPARE(application.state(), QProcess::NotRunning);
        QCOMPARE(application.exitStatus(), QProcess::NormalExit);
        QCOMPARE(application.exitCode(), 0);
        QVERIFY(wallpaper->isVisible() && dock->isVisible() && ribbon->isVisible());
        QVERIFY(capture("native-after-client-close"));
        QCOMPARE(warnings.count(), 0);
        bus.unregisterObject("/Audit");
        bus.unregisterService("org.owode.NativeAudit");
    }
    void nativeLauncherDiscoversPinsAndStartsWaylandApplication() {
        QVERIFY2(qEnvironmentVariable("OWODE_NATIVE_TEST_ISOLATED") == "1" &&
                     qEnvironmentVariable("WAYLAND_DISPLAY") == "owode-ci" &&
                     qEnvironmentVariable("XDG_RUNTIME_DIR")
                         .startsWith(QDir::tempPath() + "/owode-native-ci-"),
                 "Run only in the private cloud KWin session");
        QVERIFY(klde::DesktopApplicationBackend::available());
        m_output = qEnvironmentVariable("OWODE_NATIVE_EVIDENCE");
        QVERIFY(!m_output.isEmpty());
        const auto fixture =
            qEnvironmentVariable("XDG_DATA_HOME") + "/applications/owode-launch-fixture.desktop";
        const auto state = m_output + "/catalog-client-state.json";
        QFile desktop(fixture);
        QVERIFY(desktop.open(QIODevice::WriteOnly));
        const auto command = QStringLiteral("\"%1/owode-native-test-client\" --state \"%2\"")
                                 .arg(QCoreApplication::applicationDirPath(), state);
        desktop.write(("[Desktop Entry]\nType=Application\nName=Catalog Launch Fixture\nExec=" +
                       command + "\nIcon=utilities-terminal\nStartupNotify=true\n")
                          .toUtf8());
        desktop.close();
        auto bus = QDBusConnection::sessionBus();
        QVERIFY(bus.registerService("org.owode.NativeAudit"));
        QVERIFY(bus.registerObject("/Audit", this, QDBusConnection::ExportAllSlots));
        QQmlApplicationEngine engine;
        const auto cleanup = qScopeGuard([&] {
            snapshot("close");
            QFile::remove(fixture);
            bus.unregisterObject("/Audit");
            bus.unregisterService("org.owode.NativeAudit");
        });
        const QSignalSpy warnings(&engine, &QQmlApplicationEngine::warnings);
        engine.setProperty("owodeSystemApplications", true);
        engine.setInitialProperties({{"nativeSurfaceMode", true}, {"initialLocale", "en"}});
        engine.loadFromModule("KLDE.Shell", "Main");
        QCOMPARE(engine.rootObjects().size(), 1);
        auto *root = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
        QVERIFY(root && services);
        QTRY_VERIFY(services->desktopApplications()->ready());
        QVERIFY(!services->applications()->preview());
        QVERIFY(!services->applications()->nameFor("owode-launch-fixture.desktop").isEmpty());
        auto *dock = findWindow("nativeDockSurface");
        auto *wallpaper = findWindow("nativeWallpaperSurface");
        auto *popup = findWindow("nativePopupSurface");
        QVERIFY(dock && wallpaper && popup);
        QTRY_VERIFY(dock->isExposed() && wallpaper->isExposed());
        auto *button = findItem(dock->contentItem(), "launcherButton");
        QVERIFY(button);
        Input input;
        QVERIFY(input.valid());
        const auto point = button->mapToScene(QPointF(button->width() / 2, button->height() / 2));
        input.click(
            QPoint(qRound(point.x()), wallpaper->height() - dock->height() + qRound(point.y())));
        auto *launcher = root->findChild<QObject *>("launcher");
        QVERIFY(launcher);
        QTRY_VERIFY(popup->isExposed() && launcher->property("opened").toBool());
        for (const auto key : {KEY_F, KEY_I, KEY_X, KEY_T, KEY_U, KEY_R, KEY_E})
            input.key(static_cast<uint32_t>(key));
        QTRY_COMPARE(services->search()->query(), QString("fixture"));
        QTRY_COMPARE(services->search()->count(), 1);
        QCOMPARE(services->search()->idAt(0), QString("owode-launch-fixture.desktop"));
        input.key(KEY_LEFTSHIFT, true);
        input.key(KEY_F10);
        input.key(KEY_LEFTSHIFT, false);
        auto *menu = root->findChild<QObject *>("applicationContextMenu");
        QVERIFY(menu);
        QTRY_VERIFY(menu->property("visible").toBool());
        input.key(KEY_DOWN);
        input.key(KEY_ENTER);
        QTRY_VERIFY(services->applications()->isPinned("owode-launch-fixture.desktop"));
        QCOMPARE(services->dockApplications()->rowCount(), 1);
        QVERIFY(capture("native-catalog-launcher"));
        QSignalSpy launched(services->desktopApplications(),
                            &klde::DesktopApplicationBackend::launchFinished);
        input.key(KEY_ENTER);
        QTRY_COMPARE(launched.count(), 1);
        QVERIFY2(launched.first().at(1).toBool(), qPrintable(launched.first().at(2).toString()));
        QTRY_VERIFY(!popup->isVisible());
        QTRY_VERIFY(snapshot() && client().value("normal").toBool());
        // No click or script activation: focus must result from the real launcher request.
        QTRY_VERIFY(readObject(state).value("active").toBool());
        QVERIFY(capture("native-catalog-application"));
        QVERIFY(snapshot("close"));
        QTRY_VERIFY(snapshot() && client().isEmpty());
        QVERIFY(wallpaper->isVisible() && dock->isVisible());
        QCOMPARE(warnings.count(), 0);
    }
};

QTEST_MAIN(NativeSessionTest)
#include "test_native_session.moc"
