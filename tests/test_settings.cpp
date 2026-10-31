// SPDX-License-Identifier: GPL-3.0-or-later
#include "settings/ShellSettings.h"

#include <QSettings>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

using klde::ShellSettings;

class SettingsTest : public QObject {
    Q_OBJECT
  private slots:
    void memoryOnlyByDefault() {
        ShellSettings settings;
        QVERIFY(!settings.persistent());
        QVERIFY(settings.path().isEmpty());
        QCOMPARE(settings.value("appearance.accent").toString(), QStringLiteral("auto"));
        QVERIFY(settings.setValue("appearance.accent", QStringLiteral("teal")));
        QCOMPARE(settings.value("appearance.accent").toString(), QStringLiteral("teal"));
        // Per-scene overrides are unset until stored.
        QVERIFY(!settings.value("scenes.balanced.motion").isValid());
    }

    void rejectsValuesOutsideTheSchema() {
        ShellSettings settings;
        QSignalSpy changed(&settings, &ShellSettings::changed);
        QVERIFY(!settings.setValue("appearance.accent", QStringLiteral("neon")));
        QVERIFY(!settings.setValue("appearance.accent", 3));
        QVERIFY(!settings.setValue("ribbon.margin", 400));
        QVERIFY(!settings.setValue("ribbon.margin", 4.5));
        QVERIFY(!settings.setValue("ribbon.enabled", QStringLiteral("true")));
        QVERIFY(!settings.setValue("unknown.key", true));
        QCOMPARE(changed.count(), 0);
        QVERIFY(settings.setValue("ribbon.margin", 24.0));
        QCOMPARE(settings.value("ribbon.margin").metaType().id(), QMetaType::Int);
        QCOMPARE(changed.count(), 1);
        QVERIFY(settings.setValue("ribbon.margin", 24));
        QCOMPARE(changed.count(), 1);
    }

    void persistsAndReloads() {
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        {
            ShellSettings settings;
            QVERIFY(settings.enablePersistence(directory.path()));
            QVERIFY(settings.persistent());
            QVERIFY(settings.setValue("appearance.wallpaper", QStringLiteral("quiet")));
            QVERIFY(settings.setValue("ribbon.compact", true));
            QVERIFY(settings.setValue("scenes.balanced.motion", 0));
        }
        QSettings file(directory.filePath("shell.conf"), QSettings::IniFormat);
        QCOMPARE(file.value("meta/version").toInt(), ShellSettings::CurrentVersion);
        QCOMPARE(file.value("appearance/wallpaper").toString(), QStringLiteral("quiet"));
        ShellSettings reloaded;
        QVERIFY(reloaded.enablePersistence(directory.path()));
        QCOMPARE(reloaded.value("appearance.wallpaper").toString(), QStringLiteral("quiet"));
        QCOMPARE(reloaded.value("ribbon.compact").toBool(), true);
        QCOMPARE(reloaded.value("ribbon.compact").metaType().id(), QMetaType::Bool);
        QCOMPARE(reloaded.value("scenes.balanced.motion").toInt(), 0);
        reloaded.reset("scenes.balanced.motion");
        QVERIFY(!reloaded.value("scenes.balanced.motion").isValid());
        QSettings after(directory.filePath("shell.conf"), QSettings::IniFormat);
        QVERIFY(!after.contains("scenes/balanced/motion"));
    }

    void migratesUnversionedFilesAndDropsInvalidValues() {
        QTemporaryDir directory;
        {
            QSettings legacy(directory.filePath("shell.conf"), QSettings::IniFormat);
            legacy.setValue("appearance/accent", "lilac");
            legacy.setValue("ribbon/margin", "999");
        }
        ShellSettings settings;
        QVERIFY(settings.enablePersistence(directory.path()));
        QCOMPARE(settings.value("appearance.accent").toString(), QStringLiteral("lilac"));
        QCOMPARE(settings.value("ribbon.margin").toInt(), 16);
        QSettings file(directory.filePath("shell.conf"), QSettings::IniFormat);
        QCOMPARE(file.value("meta/version").toInt(), ShellSettings::CurrentVersion);
        QVERIFY(!file.contains("ribbon/margin"));
    }

    void neverOverwritesANewerSchema() {
        QTemporaryDir directory;
        {
            QSettings newer(directory.filePath("shell.conf"), QSettings::IniFormat);
            newer.setValue("meta/version", ShellSettings::CurrentVersion + 1);
            newer.setValue("appearance/accent", "apricot");
            newer.setValue("future/key", "kept");
        }
        ShellSettings settings;
        settings.enablePersistence(directory.path());
        QVERIFY(settings.readOnly());
        QVERIFY(!settings.persistent());
        QCOMPARE(settings.value("appearance.accent").toString(), QStringLiteral("apricot"));
        QVERIFY(settings.setValue("appearance.accent", QStringLiteral("teal")));
        QSettings file(directory.filePath("shell.conf"), QSettings::IniFormat);
        QCOMPARE(file.value("appearance/accent").toString(), QStringLiteral("apricot"));
        QCOMPARE(file.value("future/key").toString(), QStringLiteral("kept"));
        QCOMPARE(file.value("meta/version").toInt(), ShellSettings::CurrentVersion + 1);
    }

    void keysDefinedLaterAreLoaded() {
        QTemporaryDir directory;
        {
            QSettings file(directory.filePath("shell.conf"), QSettings::IniFormat);
            file.setValue("meta/version", ShellSettings::CurrentVersion);
            file.setValue("shortcuts/shell/launcher", "Meta+Space");
        }
        ShellSettings settings;
        QVERIFY(settings.enablePersistence(directory.path()));
        settings.define("shortcuts.shell.launcher", QMetaType::fromType<QString>(),
                        QStringLiteral("Ctrl+Alt+Space"));
        settings.define("shortcuts.shell.notifications", QMetaType::fromType<QString>(),
                        QStringLiteral("Meta+N"));
        QCOMPARE(settings.value("shortcuts.shell.launcher").toString(),
                 QStringLiteral("Meta+Space"));
        QCOMPARE(settings.value("shortcuts.shell.notifications").toString(),
                 QStringLiteral("Meta+N"));
    }
};

QTEST_GUILESS_MAIN(SettingsTest)
#include "test_settings.moc"
