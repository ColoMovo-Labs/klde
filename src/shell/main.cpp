// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QCommandLineParser>
#include <QDebug>
#include <QGuiApplication>
#include <QImage>
#include <QPointer>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QRegularExpression>
#include <QSGRendererInterface>
#include <QStyleHints>
#include <QTimer>
#include <QtMath>
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
    const QCommandLineOption cropOption("capture-region", "Smoke capture: full or ribbon", "region",
                                        "full");
    const QCommandLineOption focusOption("focus", "Preview the focus desktop composition");
    const QCommandLineOption lockStateOption(
        "lock-state", "Lock-screen visual state: ambient, auth, error, reduced, depth or fallback",
        "state", "ambient");
    const QCommandLineOption islandStateOption(
        "island-state",
        "System Island mock state: idle, notification, progress, privacy, authorization, media, "
        "device or critical",
        "state", "idle");
    const QCommandLineOption welcomePageOption(
        "welcome-page", "Welcome/OOBE mock page index from 0 to 9", "page", "0");
    const QCommandLineOption debugGeometryOption("debug-geometry",
                                                 "Show the development-only alignment overlay");
    const QCommandLineOption viewOption(
        QStringLiteral("view"),
        QStringLiteral("Initial preview: desktop, launcher, quick-settings, blur, power-scenes, "
                       "weather, language, input, temporal, wallpaper-effects, lock-preview, "
                       "lock-screen, welcome, gallery, waydroid"),
        QStringLiteral("view"), QStringLiteral("desktop"));
    const QCommandLineOption darkOption(QStringLiteral("dark"),
                                        QStringLiteral("Start with dark appearance"));
    const QCommandLineOption idleOption(
        QStringLiteral("audit-idle"),
        QStringLiteral("Count frames for one settled second in smoke-test mode"));
    const QCommandLineOption localeOption(QStringLiteral("locale"),
                                          QStringLiteral("Preview locale: en or zh_CN"),
                                          QStringLiteral("locale"));
    const QCommandLineOption voiceOption(QStringLiteral("voice"),
                                         QStringLiteral("Preview voice: standard or cute"),
                                         QStringLiteral("voice"));
    const QCommandLineOption scenarioOption("scenario", "Mock fixture ID", "scenario",
                                            "laptop-balanced");
    const QCommandLineOption densityOption("density", "Density: comfortable, balanced, dense",
                                           "density", "balanced");
    const QCommandLineOption wallpaperOption(
        "wallpaper", "Original wallpaper: snow, abstract, quiet, kemono", "wallpaper", "snow");
    const QCommandLineOption sizeOption("size", "Logical preview size, e.g. 1920x1080", "size",
                                        "1440x900");
    const QCommandLineOption ambientOption("ambient", "Preview the ambient workspace layout");
    const QCommandLineOption developerOption("dev-tools", "Open the session-only Mock Lab");
    parser.addOptions({scenarioOption, densityOption, wallpaperOption, sizeOption, ambientOption,
                       developerOption});
    parser.addOptions({cropOption, focusOption, lockStateOption, islandStateOption,
                       welcomePageOption, debugGeometryOption, smokeOption, captureOption,
                       viewOption, darkOption, idleOption, localeOption, voiceOption});
    parser.process(app);
    if ((parser.isSet(captureOption) || parser.isSet(idleOption)) && !parser.isSet(smokeOption)) {
        qCritical() << "--capture and --audit-idle require --smoke-test";
        return EXIT_FAILURE;
    }
    if (parser.value(cropOption) != "full" && parser.value(cropOption) != "ribbon") {
        qCritical() << "Invalid capture region";
        return EXIT_FAILURE;
    }
    const QStringList views{QStringLiteral("desktop"),
                            QStringLiteral("launcher"),
                            QStringLiteral("quick-settings"),
                            QStringLiteral("blur"),
                            QStringLiteral("power-scenes"),
                            QStringLiteral("weather"),
                            QStringLiteral("language"),
                            QStringLiteral("input"),
                            "temporal-study",
                            "temporal",
                            "wallpaper-effects",
                            "lock-preview",
                            "lock-screen",
                            "welcome",
                            "gallery",
                            "waydroid",
                            "weather-preview",
                            "quick-settings-expanded",
                            "notifications",
                            "ribbon",
                            "ribbon-settings",
                            "input-candidate",
                            "mock-lab",
                            "app-suite"};
    if (!views.contains(parser.value(viewOption))) {
        qCritical() << "Unknown preview view";
        return EXIT_FAILURE;
    }
    const QStringList lockStates{QStringLiteral("ambient"), QStringLiteral("auth"),
                                 QStringLiteral("error"),   QStringLiteral("reduced"),
                                 QStringLiteral("depth"),   QStringLiteral("fallback")};
    if (!lockStates.contains(parser.value(lockStateOption))) {
        qCritical() << "Unsupported lock-screen state";
        return EXIT_FAILURE;
    }
    const QStringList islandStates{QStringLiteral("idle"),          QStringLiteral("notification"),
                                   QStringLiteral("progress"),      QStringLiteral("privacy"),
                                   QStringLiteral("authorization"), QStringLiteral("media"),
                                   QStringLiteral("device"),        QStringLiteral("critical")};
    if (!islandStates.contains(parser.value(islandStateOption))) {
        qCritical() << "Unsupported System Island state";
        return EXIT_FAILURE;
    }
    bool welcomePageOk = false;
    const int welcomePage = parser.value(welcomePageOption).toInt(&welcomePageOk);
    if (!welcomePageOk || welcomePage < 0 || welcomePage > 10) {
        qCritical() << "Unsupported Welcome page index";
        return EXIT_FAILURE;
    }
    if ((!parser.value(localeOption).isEmpty() && parser.value(localeOption) != "en" &&
         parser.value(localeOption) != "zh_CN") ||
        (!parser.value(voiceOption).isEmpty() && parser.value(voiceOption) != "standard" &&
         parser.value(voiceOption) != "cute")) {
        qCritical() << "Unsupported locale or voice";
        return EXIT_FAILURE;
    }
    if (parser.isSet(idleOption)) {
        // A focused search cursor is useful during interaction, not an idle effect.
        QGuiApplication::styleHints()->setCursorFlashTime(0);
    }

    const QStringList densities{"comfortable", "balanced", "dense"};
    const QStringList wallpapers{"snow", "abstract", "quiet", "kemono"};
    const auto sizeMatch =
        QRegularExpression("^(\\d{3,4})x(\\d{3,4})$").match(parser.value(sizeOption));
    const int logicalWidth = sizeMatch.captured(1).toInt(),
              logicalHeight = sizeMatch.captured(2).toInt();
    if (!sizeMatch.hasMatch() || logicalWidth < 640 || logicalHeight < 640 || logicalWidth > 7680 ||
        logicalHeight > 4320 || !densities.contains(parser.value(densityOption)) ||
        !wallpapers.contains(parser.value(wallpaperOption))) {
        qCritical() << "Invalid preview size, density or wallpaper";
        return EXIT_FAILURE;
    }
    bool qmlWarnings = false;
    bool frameHandled = false;
    bool settlingEnabled = false;
    bool auditStarted = false;
    int idleFrames = 0;
    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &engine,
                     [&qmlWarnings] { qmlWarnings = true; });
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.setInitialProperties(
        {{QStringLiteral("initialView"), parser.value(viewOption)},
         {QStringLiteral("initialDark"), parser.isSet(darkOption)},
         {QStringLiteral("initialLocale"), parser.value(localeOption)},
         {QStringLiteral("initialVoice"), parser.value(voiceOption)},
         {"initialScenario", parser.value(scenarioOption)},
         {"initialDensity", densities.indexOf(parser.value(densityOption))},
         {"initialWallpaper", parser.value(wallpaperOption)},
         {"initialAmbient", parser.isSet(ambientOption) || parser.isSet(focusOption)},
         {"initialFocus", parser.isSet(focusOption)},
         {"initialLockState", parser.value(lockStateOption)},
         {"initialIslandState", parser.value(islandStateOption)},
         {"initialWelcomePage", welcomePage},
         {"initialDebugGeometry", parser.isSet(debugGeometryOption)},
         {"developerTools", parser.isSet(developerOption)},
         {"width", logicalWidth},
         {"height", logicalHeight}});
    engine.loadFromModule(QStringLiteral("KLDE.Shell"), QStringLiteral("Main"));
    if (engine.rootObjects().size() != 1) {
        return EXIT_FAILURE;
    }
    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
    if (window == nullptr || services == nullptr || !services->language()->ready()) {
        qCritical() << "The shell window or services could not be created";
        return EXIT_FAILURE;
    }
    if (services->mockScenarios()->activeId() != parser.value(scenarioOption)) {
        qCritical() << "Unknown or invalid mock scenario";
        return EXIT_FAILURE;
    }
    const QPointer<QQuickWindow> guardedWindow(window);
    QObject::connect(
        window, &QQuickWindow::sceneGraphInitialized, services,
        [guardedWindow, services] {
            if (!guardedWindow) {
                return;
            }
            const auto api = guardedWindow->rendererInterface()->graphicsApi();
            services->setGraphicsAvailable(
                api == QSGRendererInterface::OpenGL || api == QSGRendererInterface::Vulkan ||
                api == QSGRendererInterface::Metal || api == QSGRendererInterface::Direct3D11);
        },
        Qt::QueuedConnection);
    QObject::connect(
        window, &QQuickWindow::sceneGraphInvalidated, services,
        [services] { services->setGraphicsAvailable(false); }, Qt::QueuedConnection);

    if (parser.isSet(smokeOption)) {
        const auto capturePath = parser.value(captureOption);
        const bool audit = parser.isSet(idleOption);
        const bool cropRibbon = parser.value(cropOption) == "ribbon";
        const auto finish = [window, &app, &qmlWarnings, &idleFrames, capturePath, audit,
                             cropRibbon] {
            if (!capturePath.isEmpty()) {
                QImage capture = window->grabWindow();
                if (cropRibbon) {
                    auto *ribbon = window->findChild<QObject *>(QStringLiteral("statusRibbon"));
                    const auto ratio = window->devicePixelRatio();
                    const auto height = ribbon ? ribbon->property("height").toDouble() +
                                                     2 * ribbon->property("y").toDouble()
                                               : 96.0;
                    capture = capture.copy(0, 0, capture.width(), qCeil(height * ratio));
                }
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
        // A cold software renderer can take longer than a wall-clock transition
        // duration. Require an actual quiet interval before measuring idle frames.
        // Continuous rendering never reaches this gate and still hits the timeout.
        auto *settleTimer = new QTimer(window);
        settleTimer->setSingleShot(true);
        settleTimer->setInterval(300);
        QObject::connect(settleTimer, &QTimer::timeout, window,
                         [window, &idleFrames, &auditStarted, audit, finish] {
                             if (audit) {
                                 auditStarted = true;
                                 idleFrames = 0;
                                 qInfo() << "KLDE scene quiescent; idle audit begins";
                                 QTimer::singleShot(1000, window, finish);
                             } else {
                                 finish();
                             }
                         });
        QObject::connect(
            window, &QQuickWindow::frameSwapped, window,
            [window, settleTimer, &frameHandled, &idleFrames, &settlingEnabled, &auditStarted] {
                ++idleFrames;
                if (!frameHandled) {
                    frameHandled = true;
                    QTimer::singleShot(700, window, [settleTimer, &settlingEnabled] {
                        settlingEnabled = true;
                        settleTimer->start();
                    });
                } else if (settlingEnabled && !auditStarted) {
                    settleTimer->start();
                }
            },
            Qt::QueuedConnection);
        // Diagnostic-only finite timers; ordinary shell startup has no repaint timer.
        QTimer::singleShot(12000, window, [&app] {
            qCritical() << "KLDE smoke test timed out";
            app.exit(EXIT_FAILURE);
        });
        window->requestUpdate();
    }
    return app.exec();
}
