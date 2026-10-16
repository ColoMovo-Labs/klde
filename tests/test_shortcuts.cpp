// SPDX-License-Identifier: GPL-3.0-or-later
#include "shortcuts/ShortcutRegistry.h"
#include <QSignalSpy>
#include <QtTest>

class ShortcutTest final : public QObject {
    Q_OBJECT
  private slots:
    void defaultsAreApplicationScopedAndInstancesAreIsolated() {
        klde::ShortcutRegistry first;
        klde::ShortcutRegistry second;
        QCOMPARE(first.launcher(), QStringLiteral("Ctrl+Alt+Space"));
        QCOMPARE(first.actions().size(), 4);
        QVERIFY(!first.globalAvailable());
        for (const auto &action : first.actions()) {
            QCOMPARE(action.toMap().value(QStringLiteral("scope")).toString(),
                     QStringLiteral("application"));
        }
        QVERIFY(first.rebind(QStringLiteral("shell.launcher"), QStringLiteral("Ctrl+Alt+L")));
        QCOMPARE(second.launcher(), QStringLiteral("Ctrl+Alt+Space"));
    }
    void conflictsAndInvalidBindingsDoNotReplaceWorkingShortcut() {
        klde::ShortcutRegistry registry;
        QSignalSpy changed(&registry, &klde::ShortcutRegistry::bindingsChanged);
        QVERIFY(!registry.rebind(QStringLiteral("unknown"), QStringLiteral("Ctrl+Alt+L")));
        QVERIFY(!registry.rebind(QStringLiteral("shell.launcher"), QStringLiteral("F2")));
        QVERIFY(!registry.rebind(QStringLiteral("shell.launcher"), QStringLiteral("Ctrl+")));
        QVERIFY(
            !registry.rebind(QStringLiteral("shell.launcher"), QStringLiteral("Ctrl+X, Ctrl+C")));
        QVERIFY(!registry.rebind(QStringLiteral("shell.launcher"), QStringLiteral("A")));
        QVERIFY(!registry.rebind(QStringLiteral("shell.launcher"), QStringLiteral("Shift+A")));
        QCOMPARE(registry.launcher(), QStringLiteral("Ctrl+Alt+Space"));
        QCOMPARE(changed.count(), 0);
        QVERIFY(!registry.lastError().isEmpty());
    }
    void disableReassignAndResetAreExplicit() {
        klde::ShortcutRegistry registry;
        QSignalSpy changed(&registry, &klde::ShortcutRegistry::bindingsChanged);
        QVERIFY(registry.rebind(QStringLiteral("shell.quick-settings"), QString{}));
        QVERIFY(registry.quickSettings().isEmpty());
        QVERIFY(registry.rebind(QStringLiteral("shell.launcher"), QStringLiteral(" F2 ")));
        QCOMPARE(registry.launcher(), QStringLiteral("F2"));
        QVERIFY(registry.lastError().isEmpty());
        QCOMPARE(changed.count(), 2);
        QVERIFY(registry.rebind(QStringLiteral("shell.launcher"), QStringLiteral("F2")));
        QCOMPARE(changed.count(), 2);
        registry.resetDefaults();
        QCOMPARE(changed.count(), 3);
        QCOMPARE(registry.launcher(), QStringLiteral("Ctrl+Alt+Space"));
        QCOMPARE(registry.quickSettings(), QStringLiteral("F2"));
        registry.resetDefaults();
        QCOMPARE(changed.count(), 3);
    }
};
QTEST_GUILESS_MAIN(ShortcutTest)
#include "test_shortcuts.moc"
