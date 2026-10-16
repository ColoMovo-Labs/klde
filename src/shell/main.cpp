// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCommandLineParser>
#include <QDebug>
#include <QGuiApplication>
#include <QImage>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QtQml/QQmlExtensionPlugin>

#include <cstdlib>

Q_IMPORT_QML_PLUGIN(KldeShellPlugin)

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("klde-shell"));
    QCoreApplication::setApplicationVersion(QStringLiteral(KLDE_VERSION));
    QCoreApplication::setOrganizationName(QStringLiteral("KLDE"));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("KLDE Phase 0 standalone shell foundation"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption smokeOption(QStringLiteral("smoke-test"),
                                         QStringLiteral("Exit after the first rendered frame"));
    const QCommandLineOption captureOption(QStringLiteral("capture"),
                                           QStringLiteral("Save the smoke-test window as a PNG"),
                                           QStringLiteral("path"));
    parser.addOption(smokeOption);
    parser.addOption(captureOption);
    parser.process(app);
    if (parser.isSet(captureOption) && !parser.isSet(smokeOption)) {
        qCritical() << "--capture requires --smoke-test";
        return EXIT_FAILURE;
    }

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.loadFromModule(QStringLiteral("KLDE.Shell"), QStringLiteral("Main"));
    if (engine.rootObjects().size() != 1) {
        return EXIT_FAILURE;
    }
    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    if (window == nullptr) {
        qCritical() << "The shell root is not a window";
        return EXIT_FAILURE;
    }

    bool frameHandled = false;
    if (parser.isSet(smokeOption)) {
        const auto capturePath = parser.value(captureOption);
        QObject::connect(
            window, &QQuickWindow::frameSwapped, &app,
            [window, &app, &frameHandled, capturePath] {
                if (frameHandled) {
                    return;
                }
                frameHandled = true;
                if (!capturePath.isEmpty()) {
                    const QImage capture = window->grabWindow();
                    if (capture.isNull() || !capture.save(capturePath, "PNG")) {
                        qCritical() << "Failed to save smoke capture";
                        app.exit(EXIT_FAILURE);
                        return;
                    }
                }
                qInfo() << "KLDE smoke test: a window frame was rendered";
                app.exit(EXIT_SUCCESS);
            },
            Qt::QueuedConnection);
        // A bounded diagnostic watchdog, absent during an ordinary shell run.
        QTimer::singleShot(10000, &app, [&app] {
            qCritical() << "KLDE smoke test timed out waiting for a frame";
            app.exit(EXIT_FAILURE);
        });
        window->requestUpdate();
    }
    return app.exec();
}
