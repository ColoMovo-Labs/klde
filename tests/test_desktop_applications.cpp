// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QSettings>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtQml/QQmlExtensionPlugin>
#include <QtTest>
#include <algorithm>

Q_IMPORT_QML_PLUGIN(KldeBackendsPlugin)

namespace {
QString dataRoot;
QString systemRoot;
void writeFile(const QString &path, const QByteArray &content) {
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly) || file.write(content) != content.size())
        qFatal("Could not create isolated desktop fixture");
}
bool contains(const klde::DesktopApplicationBackend &backend, const QString &id) {
    for (const auto &entry : backend.entries())
        if (entry.id == id)
            return true;
    return false;
}
bool hasName(const klde::DesktopApplicationBackend &backend, const QString &name) {
    for (const auto &entry : backend.entries())
        if (entry.name == name)
            return true;
    return false;
}
QString quote(QString text) {
    text.replace('\\', "\\\\");
    text.replace('"', "\\\"");
    return '"' + text + '"';
}
} // namespace

class DesktopApplicationsTest final : public QObject {
    Q_OBJECT
  private slots:
    void initTestCase() {
        QVERIFY2(klde::DesktopApplicationBackend::available(),
                 "Cloud application contracts must compile the KF6 implementation");
        const QByteArray base("[Desktop Entry]\nType=Application\nName=Fixture\nExec=/bin/true\n");
        writeFile(systemRoot + "/applications/override.desktop", base);
        writeFile(dataRoot + "/applications/override.desktop", base + "Name=User override\n");
        writeFile(systemRoot + "/applications/hidden.desktop", base);
        writeFile(dataRoot + "/applications/hidden.desktop", base + "Hidden=true\n");
        writeFile(dataRoot + "/applications/no-display.desktop", base + "NoDisplay=true\n");
        writeFile(dataRoot + "/applications/other.desktop", base + "OnlyShowIn=OtherDesktop;\n");
        writeFile(dataRoot + "/applications/excluded.desktop", base + "NotShowIn=owoDE;\n");
        writeFile(dataRoot + "/applications/missing.desktop",
                  base + "TryExec=owode-no-such-command\n");
        writeFile(dataRoot + "/applications/suite/child.desktop",
                  base + "Name=Child\nName[zh_CN]=子应用\nKeywords=fixture;searchable;\nIcon=" +
                      (dataRoot + "/fixture.svg\n").toUtf8());
        writeFile(dataRoot + "/fixture.svg",
                  "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"32\" height=\"32\"><rect "
                  "width=\"32\" height=\"32\" fill=\"#368866\"/></svg>");
    }
    void discoversXdgPrecedenceVisibilityAndStableIds() {
        klde::DesktopApplicationBackend backend;
        backend.setLocale("en_US");
        backend.start();
        QTRY_VERIFY(backend.ready());
        QCOMPARE(backend.entries().size(), 2);
        QVERIFY(contains(backend, "suite-child.desktop"));
        QVERIFY(contains(backend, "override.desktop"));
        const auto icon = backend.icon("suite-child.desktop", QSize(32, 32));
        QCOMPARE(icon.size(), QSize(32, 32));
        QVERIFY(icon.pixelColor(16, 16).alpha() > 0);
        for (const auto &entry : backend.entries()) {
            QCOMPARE(entry.origin, "system");
            QVERIFY(!entry.running && !entry.active);
            QVERIFY(entry.icon.startsWith("image://applications/"));
            if (entry.id == "override.desktop")
                QCOMPARE(entry.name, "User override");
        }
        backend.setLocale("zh_CN");
        QTRY_VERIFY(hasName(backend, QStringLiteral("子应用")));
    }
    void watchesInstallationEditingAndRemovalWithoutPolling() {
        klde::DesktopApplicationBackend backend;
        backend.start();
        QTRY_VERIFY(backend.ready());
        const auto path = dataRoot + "/applications/hot.desktop";
        writeFile(path, "[Desktop Entry]\nType=Application\nName=Hot install\nExec=/bin/true\n");
        QTRY_VERIFY(contains(backend, "hot.desktop"));
        writeFile(
            path,
            "[Desktop Entry]\nType=Application\nName=Hidden now\nExec=/bin/true\nNoDisplay=true\n");
        QTRY_VERIFY(!contains(backend, "hot.desktop"));
        QVERIFY(QFile::remove(path));
    }
    void gnomeAndKdeMenuEntriesRemainVisibleWithoutGlobalImpersonation() {
        const auto folder = dataRoot + "/applications/";
        const QByteArray base(
            "[Desktop Entry]\nType=Application\nName=Compatibility fixture\nExec=/bin/true\n");
        writeFile(folder + "gnome.desktop", base + "OnlyShowIn=GNOME;\n");
        writeFile(folder + "kde.desktop", base + "OnlyShowIn=KDE;\n");
        writeFile(folder + "excluded-compat.desktop",
                  base + "OnlyShowIn=GNOME;KDE;\nNotShowIn=owoDE;\n");
        klde::DesktopApplicationBackend backend;
        backend.start();
        QTRY_VERIFY(backend.ready());
        QVERIFY(contains(backend, "gnome.desktop"));
        QVERIFY(contains(backend, "kde.desktop"));
        QVERIFY(!contains(backend, "excluded-compat.desktop"));
        QVERIFY(!contains(backend, "other.desktop"));
        QCOMPARE(qEnvironmentVariable("XDG_CURRENT_DESKTOP"), QString("owoDE"));
        QSignalSpy result(&backend, &klde::DesktopApplicationBackend::launchFinished);
        QVERIFY(backend.launch("gnome.desktop"));
        QTRY_COMPARE(result.count(), 1);
        QVERIFY(result.first().at(1).toBool());
        QVERIFY(backend.launch("kde.desktop"));
        QTRY_COMPARE(result.count(), 2);
        QVERIFY(result.last().at(1).toBool());
        for (const auto &id : {"gnome.desktop", "kde.desktop", "excluded-compat.desktop"})
            QVERIFY(QFile::remove(folder + id));
    }
    void launchesWithDesktopFieldCodesWorkingDirectoryAndLiteralArguments() {
        const auto marker = dataRoot + "/launch result.json";
        const auto path = dataRoot + "/applications/launch.desktop";
        const QString name = "Launch literal ; dollar $value";
        const auto exec = quote(QCoreApplication::applicationFilePath()) + " --launch-fixture " +
                          quote(marker) + " \"two words\" %c %k %%";
        writeFile(path, ("[Desktop Entry]\nType=Application\nName=" + name + "\nExec=" + exec +
                         "\nPath=" + dataRoot + "\nStartupNotify=false\n")
                            .toUtf8());
        klde::DesktopApplicationBackend backend;
        backend.start();
        QTRY_VERIFY(backend.ready());
        QSignalSpy result(&backend, &klde::DesktopApplicationBackend::launchFinished);
        QVERIFY(!backend.launch("../../not-in-catalog.desktop"));
        QVERIFY(backend.launch("launch.desktop"));
        QTRY_COMPARE(result.count(), 1);
        QVERIFY2(result.first().at(1).toBool(), qPrintable(result.first().at(2).toString()));
        QTRY_VERIFY(QFileInfo::exists(marker));
        QFile file(marker);
        QVERIFY(file.open(QIODevice::ReadOnly));
        const auto output = QJsonDocument::fromJson(file.readAll()).object();
        QCOMPARE(output["directory"].toString(), dataRoot);
        QCOMPARE(output["arguments"].toArray(), QJsonArray({"two words", name, path, "%"}));
        for (const auto &entry : backend.entries())
            QVERIFY(!entry.running && !entry.active);
        // The watcher has not necessarily delivered removal yet: launch revalidates the file.
        QVERIFY(QFile::remove(path));
        QVERIFY(!backend.launch("launch.desktop"));
        QVERIFY(QFile::remove(marker));
    }
    void pinsPersistAndDockFiltersInstalledApplications() {
        klde::DesktopApplicationBackend backend;
        backend.start();
        QTRY_VERIFY(backend.ready());
        klde::ApplicationModel applications;
        klde::DockApplicationModel dock(&applications);
        klde::ApplicationFilterModel search(&applications);
        QObject::connect(&backend, &klde::DesktopApplicationBackend::catalogChanged, &applications,
                         [&] { applications.replaceSystemApplications(backend.entries()); });
        QObject::connect(&applications, &klde::ApplicationModel::pinRequested, &backend,
                         &klde::DesktopApplicationBackend::setPinned);
        applications.replaceSystemApplications(backend.entries());
        QVERIFY(!applications.preview());
        QCOMPARE(dock.rowCount(), 0);
        QCOMPARE(search.count(), applications.rowCount());
        applications.setPinned("suite-child.desktop", true);
        QCOMPARE(dock.rowCount(), 1);
        QVERIFY(applications.isPinned("suite-child.desktop"));
        QVERIFY(!applications.activate("suite-child.desktop"));
        applications.resetPreview("terminal");
        QVERIFY(!applications.nameFor("suite-child.desktop").isEmpty());
        klde::DesktopApplicationBackend reopened;
        reopened.start();
        QTRY_VERIFY(reopened.ready());
        const auto reopenedEntries = reopened.entries();
        QVERIFY(std::any_of(reopenedEntries.cbegin(), reopenedEntries.cend(),
                            [](const auto &entry) { return entry.pinned; }));
        applications.setPinned("suite-child.desktop", false);
        QCOMPARE(dock.rowCount(), 0);
    }
    void failedLaunchReportsFailureWithoutInventingRunningState() {
        const auto path = dataRoot + "/applications/failure.desktop";
        writeFile(path, "[Desktop Entry]\nType=Application\nName=Failure "
                        "fixture\nExec=owode-no-such-executable\nStartupNotify=false\n");
        klde::DesktopApplicationBackend backend;
        backend.start();
        QTRY_VERIFY(backend.ready());
        QSignalSpy result(&backend, &klde::DesktopApplicationBackend::launchFinished);
        QVERIFY(backend.launch("failure.desktop"));
        QTRY_COMPARE(result.count(), 1);
        QVERIFY(!result.first().at(1).toBool());
        QVERIFY(!result.first().at(2).toString().isEmpty());
        for (const auto &entry : backend.entries())
            QVERIFY(!entry.running && !entry.active);
        QVERIFY(QFile::remove(path));
    }
    void qmlFactorySelectsRealCatalogAndKeepsOrdinaryPreviewMock() {
        QQmlEngine engine;
        engine.setProperty("owodeSystemApplications", true);
        QQmlComponent component(&engine);
        component.setData("import QtQml\nimport KLDE.Backends\nQtObject { property var apps: "
                          "Shell.applications }",
                          QUrl());
        QScopedPointer<QObject> object(component.create());
        QVERIFY2(object, qPrintable(component.errorString()));
        auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
        QVERIFY(services);
        QVERIFY(!services->applications()->preview());
        QVERIFY(!services->time()->reading().value("mock").toBool());
        // Kernel counters are always readable; their fixture values must be replaced.
        QVERIFY(services->state()->isLive("memory.usedPercent"));
        QVERIFY(services->state()->isLive("capabilities.battery"));
        QTRY_VERIFY(services->desktopApplications()->ready());
        QVERIFY(!services->applications()->nameFor("suite-child.desktop").isEmpty());
        klde::ShellServices preview(nullptr);
        QVERIFY(preview.applications()->preview());
        QVERIFY(preview.time()->reading().value("mock").toBool());
        QVERIFY(preview.state()->livePaths().isEmpty());
        QVERIFY(!preview.applications()->nameFor("terminal").isEmpty());
    }
    void compositorIdentityMatchingIsExplicitAndRejectsAmbiguousAliases() {
        const auto folder = dataRoot + "/applications/";
        const QByteArray base("[Desktop Entry]\nType=Application\nExec=/bin/true\n");
        writeFile(folder + "org.owode.Editor.desktop",
                  base + "Name=Editor\nStartupWMClass=OldEditor\n");
        klde::DesktopApplicationBackend backend;
        backend.start();
        QTRY_VERIFY(backend.ready());
        QCOMPARE(backend.applicationForWindow("org.owode.Editor", {}, {}),
                 "org.owode.Editor.desktop");
        QCOMPARE(backend.applicationForWindow(folder + "org.owode.Editor.desktop", {}, {}),
                 "org.owode.Editor.desktop");
        QCOMPARE(backend.applicationForWindow({}, "oldeditor", {}), "org.owode.Editor.desktop");
        QVERIFY(backend.applicationForWindow({}, "not-OldEditor", {}).isEmpty());
        writeFile(folder + "other-editor.desktop",
                  base + "Name=Other editor\nStartupWMClass=OldEditor\n");
        QTRY_VERIFY(contains(backend, "other-editor.desktop"));
        QVERIFY(backend.applicationForWindow({}, "OldEditor", {}).isEmpty());
        QCOMPARE(backend.applicationForWindow("org.owode.Editor", "OldEditor", {}),
                 "org.owode.Editor.desktop");
        QVERIFY(QFile::remove(folder + "org.owode.Editor.desktop"));
        QVERIFY(QFile::remove(folder + "other-editor.desktop"));
    }
    void runtimeBadgesSurviveCatalogRefreshWithoutInventingProcesses() {
        klde::ApplicationModel model;
        klde::DockApplicationModel dock(&model);
        const klde::ApplicationEntry installed{
            "editor.desktop", "Editor", {}, "note", {}, false, false, "system", false};
        model.replaceSystemApplications({installed});
        QCOMPARE(dock.rowCount(), 0);
        auto running = installed;
        running.running = true;
        running.active = true;
        QSignalSpy reset(&model, &QAbstractItemModel::modelReset);
        model.setRuntimeApplications({running});
        QCOMPARE(reset.count(), 0);
        QCOMPARE(dock.rowCount(), 1);
        QCOMPARE(model.activeId(), "editor.desktop");
        QCOMPARE(model.activeName(), "Editor");
        model.replaceSystemApplications({installed});
        QCOMPARE(reset.count(), 0);
        QCOMPARE(dock.rowCount(), 1);
        QVERIFY(model.canPin("editor.desktop"));
        QSignalSpy active(&model, &klde::ApplicationModel::activeChanged);
        auto renamed = installed;
        renamed.name = "Localized editor";
        model.replaceSystemApplications({renamed});
        QCOMPARE(model.activeName(), "Localized editor");
        QCOMPARE(model.activeId(), "editor.desktop");
        QCOMPARE(active.count(), 1);
        const klde::ApplicationEntry unmatched{"window:opaque-id",
                                               "Uncatalogued window",
                                               {},
                                               "note",
                                               {},
                                               true,
                                               false,
                                               "window",
                                               false};
        model.setRuntimeApplications({running, unmatched});
        QCOMPARE(dock.rowCount(), 2);
        QVERIFY(!model.canPin(unmatched.id));
        model.setRuntimeApplications({unmatched});
        QCOMPARE(dock.rowCount(), 1);
        QCOMPARE(model.activeId(), "desktop");
        auto another = unmatched;
        another.id = "window:another-id";
        another.name = "Another uncatalogued window";
        model.setRuntimeApplications({unmatched, another});
        QSignalSpy reordered(&model, &QAbstractItemModel::modelReset);
        model.setRuntimeApplications({another, unmatched});
        QCOMPARE(model.data(model.index(1, 0), klde::ApplicationModel::AppIdRole).toString(),
                 unmatched.id);
        QCOMPARE(model.data(model.index(2, 0), klde::ApplicationModel::AppIdRole).toString(),
                 another.id);
        QCOMPARE(reordered.count(), 0);
        model.setRuntimeApplications({});
        QCOMPARE(dock.rowCount(), 0);
        QCOMPARE(model.rowCount(), 1);
    }
};

int main(int argc, char **argv) {
    if (argc > 2 && QByteArray(argv[1]) == "--launch-fixture") {
        QJsonArray arguments;
        for (int i = 3; i < argc; ++i)
            arguments.append(QString::fromLocal8Bit(argv[i]));
        writeFile(
            QString::fromLocal8Bit(argv[2]),
            QJsonDocument(QJsonObject{{"directory", QDir::currentPath()}, {"arguments", arguments}})
                .toJson());
        return 0;
    }
    QTemporaryDir isolated;
    if (!isolated.isValid())
        return 1;
    dataRoot = isolated.path() + "/user";
    systemRoot = isolated.path() + "/system";
    qputenv("XDG_DATA_HOME", dataRoot.toUtf8());
    qputenv("XDG_DATA_DIRS", systemRoot.toUtf8());
    qputenv("XDG_CONFIG_HOME", (isolated.path() + "/config").toUtf8());
    qputenv("XDG_CACHE_HOME", (isolated.path() + "/cache").toUtf8());
    qputenv("XDG_CURRENT_DESKTOP", "owoDE");
    QGuiApplication app(argc, argv);
    app.setOrganizationName("owoDE-tests");
    app.setApplicationName("isolated-applications");
    DesktopApplicationsTest tests;
    return QTest::qExec(&tests, argc, argv);
}
#include "test_desktop_applications.moc"
