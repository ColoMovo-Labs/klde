// SPDX-License-Identifier: GPL-3.0-or-later
#include <QDir>
#include <QFileInfo>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickView>
#include <QSignalSpy>
#include <QtTest>

// Intentionally links no shell or C++ backend plugin: this is the same source
// tree and import path that a designer opens, not the compiled runtime module.
class DesignWorkspaceTest : public QObject {
    Q_OBJECT
  private slots:
    void scenes_data() {
        QTest::addColumn<QString>("scene");
        const QDir directory(QStringLiteral(OWODE_DESIGN_DIR "/scenes"));
        for (const auto &file : directory.entryList({QStringLiteral("*.ui.qml")}, QDir::Files)) {
            QTest::newRow(qPrintable(file)) << file;
        }
    }
    void scenes() {
        QFETCH(QString, scene);
        QQuickView view;
        view.engine()->addImportPath(QStringLiteral(OWODE_DESIGN_DIR));
        view.setSource(QUrl::fromLocalFile(QStringLiteral(OWODE_DESIGN_DIR "/scenes/") + scene));
        const auto errors = view.errors();
        QVERIFY2(view.status() == QQuickView::Ready,
                 qPrintable(errors.isEmpty() ? QStringLiteral("No root object")
                                             : errors.first().toString()));
        QVERIFY(view.rootObject());
        QVERIFY(view.rootObject()->width() > 0);
        QVERIFY(view.rootObject()->height() > 0);
        view.show();
        QVERIFY(QTest::qWaitForWindowExposed(&view));
        QTest::qWait(150);
        const QString output = qEnvironmentVariable("OWODE_DESIGN_CAPTURES");
        if (!output.isEmpty()) {
            QVERIFY(QDir().mkpath(output));
            const auto image = view.grabWindow();
            QVERIFY(!image.isNull());
            QVERIFY(image.save(output + QLatin1Char('/') + scene + QStringLiteral(".png")));
        }
    }
};
QTEST_MAIN(DesignWorkspaceTest)
#include "test_design_workspace.moc"
