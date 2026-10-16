// SPDX-License-Identifier: GPL-3.0-or-later
#include <QImageReader>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QSignalSpy>
#include <QtQml/QQmlExtensionPlugin>
#include <QtTest>

Q_IMPORT_QML_PLUGIN(KldeShellPlugin)
Q_IMPORT_QML_PLUGIN(KldeBackendsPlugin)

class ShellStartupTest final : public QObject {
    Q_OBJECT
  private slots:
    void loadsPackagedModuleWithoutQmlWarnings() {
        QVERIFY2(QImageReader::supportedImageFormats().contains("svg"),
                 "The Qt SVG image plugin is required (Ubuntu: qt6-svg-plugins)");
        QQmlApplicationEngine engine;
        const QSignalSpy warnings(&engine, &QQmlApplicationEngine::warnings);
        engine.loadFromModule(QStringLiteral("KLDE.Shell"), QStringLiteral("Main"));
        QCOMPARE(engine.rootObjects().size(), 1);
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        QVERIFY(window != nullptr);
        QVERIFY(window->isVisible());
        QVERIFY(window->title().contains(QStringLiteral("KLDE")));
        QVERIFY(window->findChild<QObject *>(QStringLiteral("statusLabel")) != nullptr);
        QCoreApplication::processEvents();
        QCOMPARE(warnings.count(), 0);
        window->close();
    }
};

QTEST_MAIN(ShellStartupTest)
#include "test_startup.moc"
