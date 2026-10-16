// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QCommandLineParser>
#include <QDebug>
#include <QGuiApplication>
#include <QImage>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QStyleHints>
#include <QTimer>
#include <QtQml/QQmlExtensionPlugin>
#include <cstdlib>

Q_IMPORT_QML_PLUGIN(KldeShellPlugin)
Q_IMPORT_QML_PLUGIN(KldeBackendsPlugin)

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("klde-shell"));
    QCoreApplication::setApplicationVersion(QStringLiteral(KLDE_VERSION));
    QCoreApplication::setOrganizationName(QStringLiteral("KLDE"));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("KLDE standalone desktop-shell preview"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption smokeOption(
        QStringLiteral("smoke-test"), QStringLiteral("Capture a settled preview frame and exit"));
    const QCommandLineOption captureOption(QStringLiteral("capture"),
                                           QStringLiteral("Save the smoke-test window as a PNG"),
                                           QStringLiteral("path"));
    const QCommandLineOption viewOption(
        QStringLiteral("view"),
        QStringLiteral("Initial preview: desktop, launcher, quick-settings, blur"),
        QStringLiteral("view"), QStringLiteral("desktop"));
    const QCommandLineOption darkOption(QStringLiteral("dark"),
                                        QStringLiteral("Start with dark appearance"));
    const QCommandLineOption idleOption(
        QStringLiteral("audit-idle"),
        QStringLiteral("Count frames for one settled second in smoke-test mode"));
    parser.addOptions({smokeOption, captureOption, viewOption, darkOption, idleOption});
    parser.process(app);
    if ((parser.isSet(captureOption) || parser.isSet(idleOption)) && !parser.isSet(smokeOption)) {
        qCritical() << "--capture and --audit-idle require --smoke-test";
        return EXIT_FAILURE;
    }
    const QStringList views{QStringLiteral("desktop"), QStringLiteral("launcher"),
                            QStringLiteral("quick-settings"), QStringLiteral("blur")};
    if (!views.contains(parser.value(viewOption))) {
        qCritical() << "Unknown preview view";
        return EXIT_FAILURE;
    }
    if (parser.isSet(idleOption)) {
        // A focused search cursor is useful during interaction, not an idle effect.
        QGuiApplication::styleHints()->setCursorFlashTime(0);
    }

    QQmlApplicationEngine engine;
    bool qmlWarnings = false;
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app,
                     [&qmlWarnings] { qmlWarnings = true; });
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.setInitialProperties({{QStringLiteral("initialView"), parser.value(viewOption)},
                                 {QStringLiteral("initialDark"), parser.isSet(darkOption)}});
    engine.loadFromModule(QStringLiteral("KLDE.Shell"), QStringLiteral("Main"));
    if (engine.rootObjects().size() != 1) {
        return EXIT_FAILURE;
    }
    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
    if (window == nullptr || services == nullptr) {
        qCritical() << "The shell window or services could not be created";
        return EXIT_FAILURE;
    }
    QObject::connect(
        window, &QQuickWindow::sceneGraphInitialized, &app,
        [window, services] {
            const auto api = window->rendererInterface()->graphicsApi();
            services->setGraphicsAvailable(
                api == QSGRendererInterface::OpenGL || api == QSGRendererInterface::Vulkan ||
                api == QSGRendererInterface::Metal || api == QSGRendererInterface::Direct3D11);
        },
        Qt::QueuedConnection);
    QObject::connect(
        window, &QQuickWindow::sceneGraphInvalidated, &app,
        [services] { services->setGraphicsAvailable(false); }, Qt::QueuedConnection);

    bool frameHandled = false;
    int idleFrames = 0;
    if (parser.isSet(smokeOption)) {
        const auto capturePath = parser.value(captureOption);
        const bool audit = parser.isSet(idleOption);
        const auto finish = [window, &app, &qmlWarnings, &idleFrames, capturePath, audit] {
            if (!capturePath.isEmpty()) {
                const QImage capture = window->grabWindow();
                if (capture.isNull() || !capture.save(capturePath, "PNG")) {
                    qCritical() << "Failed to save smoke capture";
                    app.exit(EXIT_FAILURE);
                    return;
                }
            }
            if (qmlWarnings || (audit && idleFrames > 2)) {
                for (const auto *object : window->findChildren<QObject *>()) {
                    if (object->property("running").toBool()) {
                        qWarning()
                            << "Active animation:" << object->metaObject()->className()
                            << object->objectName() << "duration:" << object->property("duration")
                            << "loops:" << object->property("loops");
                    }
                }
                qCritical() << "Smoke validation failed; QML warnings:" << qmlWarnings
                            << "idle frames:" << idleFrames << "cursor flash interval:"
                            << QGuiApplication::styleHints()->cursorFlashTime();
                app.exit(EXIT_FAILURE);
                return;
            }
            qInfo() << "KLDE smoke test: settled frame rendered; idle audit:" << audit
                    << "frames:" << idleFrames;
            app.exit(EXIT_SUCCESS);
        };
        QObject::connect(
            window, &QQuickWindow::frameSwapped, &app,
            [&app, &frameHandled, &idleFrames, audit, finish] {
                ++idleFrames;
                if (frameHandled) {
                    return;
                }
                frameHandled = true;
                QTimer::singleShot(700, &app, [&app, &idleFrames, audit, finish] {
                    if (audit) {
                        idleFrames = 0;
                        QTimer::singleShot(1000, &app, finish);
                    } else {
                        finish();
                    }
                });
            },
            Qt::QueuedConnection);
        // Diagnostic-only finite timers; ordinary shell startup has no repaint timer.
        QTimer::singleShot(12000, &app, [&app] {
            qCritical() << "KLDE smoke test timed out";
            app.exit(EXIT_FAILURE);
        });
        window->requestUpdate();
    }
    return app.exec();
}
