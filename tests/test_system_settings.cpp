// SPDX-License-Identifier: GPL-3.0-or-later
#include "platform/common/SystemSettingsBridge.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QScopeGuard>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>

namespace {
void makeFile(const QString &path) {
    QVERIFY(QDir().mkpath(QFileInfo(path).absolutePath()));
    QFile file(path);
    QVERIFY(file.open(QIODevice::WriteOnly));
    QCOMPARE(file.write("fixture"), qint64{7});
}

QJsonObject readResult(const QString &path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return QJsonDocument::fromJson(file.readAll()).object();
}
} // namespace

class SystemSettingsTest final : public QObject {
    Q_OBJECT
  private slots:
    void unavailableProvidersAndUnsafePanelsAreRejected() {
        klde::SystemSettingsBridge bridge({}, {});
        bridge.setEnabled(true);
        QCOMPARE(bridge.entries().size(), 14);
        QSignalSpy failed(&bridge, &klde::SystemSettingsBridge::failed);
        for (const auto *panel : {"wifi", "kcm_kscreen", "power", "display", "keyboard", "mouse",
                                  "background", "kcm_screenlocker", "wifi;touch /tmp/unwanted"}) {
            QVERIFY(!bridge.available(QString::fromLatin1(panel)));
            QVERIFY(!bridge.open(QString::fromLatin1(panel)));
        }
        QCOMPARE(failed.count(), 9);
    }

    void discoversModulesAndRefreshesAfterInstallation() {
        QTemporaryDir root;
        QVERIFY(root.isValid());
        klde::SystemSettingsBridge bridge({root.path()}, {root.path()});
        QVERIFY(!bridge.available(QStringLiteral("kcm_kscreen")));
        QVERIFY(QFile::link(QCoreApplication::applicationFilePath(), root.filePath("kcmshell6")));
        makeFile(root.filePath("plasma/kcms/systemsettings/kcm_kscreen.so"));
        makeFile(root.filePath("plasma/kcms/systemsettings_qwidgets/kcm_kwinoptions.so"));
        QSignalSpy changed(&bridge, &klde::SystemSettingsBridge::changed);
        bridge.refresh();
        QCOMPARE(changed.count(), 1);
        QVERIFY(bridge.available(QStringLiteral("kcm_kscreen")));
        QVERIFY(bridge.available(QStringLiteral("kcm_kwinoptions")));
        QVERIFY(!bridge.available(QStringLiteral("kcm_kwinrules")));
        bridge.refresh();
        QCOMPARE(changed.count(), 1);
        QVERIFY(QFile::remove(root.filePath("kcmshell6")));
        bridge.refresh();
        QVERIFY(!bridge.available(QStringLiteral("kcm_kscreen")));
    }

    void previewNeverStartsInstalledSettings() {
        QTemporaryDir root;
        QVERIFY(root.isValid());
        QVERIFY(QFile::link(QCoreApplication::applicationFilePath(),
                            root.filePath("gnome-control-center")));
        klde::SystemSettingsBridge bridge({root.path()}, {});
        QVERIFY(bridge.available(QStringLiteral("network")));
        QVERIFY(!bridge.enabled());
        QSignalSpy opened(&bridge, &klde::SystemSettingsBridge::opened);
        QVERIFY(!bridge.open(QStringLiteral("network")));
        QCOMPARE(opened.count(), 0);
    }

    void childIdentityPreservesSessionAndDisplay_data() {
        QTest::addColumn<QString>("program");
        QTest::addColumn<QString>("panel");
        QTest::addColumn<QString>("desktop");
        QTest::newRow("gnome") << "gnome-control-center" << "network" << "GNOME";
        QTest::newRow("kwin") << "kcmshell6" << "kcm_kscreen" << "owoDE";
    }

    void childIdentityPreservesSessionAndDisplay() {
        QFETCH(QString, program);
        QFETCH(QString, panel);
        QFETCH(QString, desktop);
        QTemporaryDir root;
        QVERIFY(root.isValid());
        const auto output = root.filePath("result with spaces.json");
        QVERIFY(QFile::link(QCoreApplication::applicationFilePath(), root.filePath(program)));
        makeFile(root.filePath("plasma/kcms/systemsettings/kcm_kscreen.so"));
        qputenv("OWODE_SETTINGS_PROBE_OUTPUT", output.toUtf8());
        const auto previous = qgetenv("XDG_CURRENT_DESKTOP");
        const bool wasSet = qEnvironmentVariableIsSet("XDG_CURRENT_DESKTOP");
        const auto restore = qScopeGuard([&] {
            qunsetenv("OWODE_SETTINGS_PROBE_OUTPUT");
            if (wasSet)
                qputenv("XDG_CURRENT_DESKTOP", previous);
            else
                qunsetenv("XDG_CURRENT_DESKTOP");
        });
        qputenv("XDG_CURRENT_DESKTOP", "owoDE");
        klde::SystemSettingsBridge bridge({root.path()}, {root.path()});
        bridge.setEnabled(true);
        QSignalSpy opened(&bridge, &klde::SystemSettingsBridge::opened);
        QVERIFY(bridge.open(panel));
        QCOMPARE(opened.count(), 1);
        QTRY_VERIFY(!readResult(output).isEmpty());
        const auto result = readResult(output);
        QCOMPARE(result.value("arguments").toArray(), QJsonArray{panel});
        QCOMPARE(result.value("XDG_CURRENT_DESKTOP").toString(), desktop);
        for (const auto *name : {"XDG_SESSION_DESKTOP", "XDG_SESSION_TYPE", "WAYLAND_DISPLAY",
                                 "DISPLAY", "DBUS_SESSION_BUS_ADDRESS", "GSETTINGS_SCHEMA_DIR"})
            QCOMPARE(result.value(QLatin1StringView(name)).toString(), qEnvironmentVariable(name));
        QCOMPARE(qEnvironmentVariable("XDG_CURRENT_DESKTOP"), QStringLiteral("owoDE"));
        QVERIFY(QFile::remove(root.filePath(program)));
        QVERIFY(!bridge.open(panel));
    }
};

int main(int argc, char **argv) {
    // Fake providers re-execute this binary. They record only selected values,
    // never launch host settings or contact the actual user's D-Bus services.
    QCoreApplication application(argc, argv);
    const auto name = QFileInfo(QString::fromLocal8Bit(argv[0])).fileName();
    if ((name == QStringLiteral("gnome-control-center") || name == QStringLiteral("kcmshell6")) &&
        qEnvironmentVariableIsSet("OWODE_SETTINGS_PROBE_OUTPUT")) {
        QJsonObject result{
            {"arguments", QJsonArray::fromStringList(application.arguments().mid(1))}};
        for (const auto *key :
             {"XDG_CURRENT_DESKTOP", "XDG_SESSION_DESKTOP", "XDG_SESSION_TYPE", "WAYLAND_DISPLAY",
              "DISPLAY", "DBUS_SESSION_BUS_ADDRESS", "GSETTINGS_SCHEMA_DIR"})
            result.insert(QLatin1StringView(key), qEnvironmentVariable(key));
        QFile file(qEnvironmentVariable("OWODE_SETTINGS_PROBE_OUTPUT"));
        if (!file.open(QIODevice::WriteOnly))
            return 1;
        return file.write(QJsonDocument(result).toJson()) > 0 ? 0 : 1;
    }
    SystemSettingsTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "test_system_settings.moc"
