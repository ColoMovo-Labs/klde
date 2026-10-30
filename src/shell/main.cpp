// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QCommandLineParser>
#include <QDBusConnection>
#include <QDebug>
#include <QGuiApplication>
#include <QIcon>
#include <QImage>
#include <QPointer>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QRegularExpression>
#include <QSGRendererInterface>
#include <QStringList>
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
    QGuiApplication::setDesktopFileName(QStringLiteral("org.klde.shell.preview"));
    QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/assets/branding/owode-logo.png")));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("KLDE standalone desktop-shell preview"));
    parser.addHelpOption();
    parser.addVersionOption();
    const QStringList previewViews{
        QStringLiteral("desktop"),           QStringLiteral("launcher"),
        QStringLiteral("quick-settings"),    QStringLiteral("blur"),
        QStringLiteral("power-scenes"),      QStringLiteral("weather"),
        QStringLiteral("language"),          QStringLiteral("input"),
        QStringLiteral("temporal-study"),    QStringLiteral("temporal"),
        QStringLiteral("wallpaper-effects"), QStringLiteral("lock-preview"),
        QStringLiteral("lock-screen"),       QStringLiteral("welcome"),
        QStringLiteral("gallery"),           QStringLiteral("waydroid"),
        QStringLiteral("weather-preview"),   QStringLiteral("quick-settings-expanded"),
        QStringLiteral("notifications"),     QStringLiteral("ribbon"),
        QStringLiteral("ribbon-settings"),   QStringLiteral("input-candidate"),
        QStringLiteral("mock-lab"),          QStringLiteral("app-suite"),
        QStringLiteral("material-study")};
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
        "welcome-page", "Welcome/OOBE mock page index from 0 to 10", "page", "0");
    const QCommandLineOption debugGeometryOption("debug-geometry",
                                                 "Show the development-only alignment overlay");
    const QCommandLineOption viewOption(
        QStringLiteral("view"),
        QStringLiteral("Initial preview: %1").arg(previewViews.join(QStringLiteral(", "))),
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
    const QCommandLineOption nativeSurfaceOption(
        "native-shell-surfaces",
        "Use LayerShellQt wallpaper, ribbon and dock surfaces (Wayland/KWin only)");
    const QCommandLineOption applicationsOption(
        "applications",
        "Application catalog: system or mock (default: system in native mode, mock in preview)",
        "source");
    const QCommandLineOption managedSessionOption(
        "managed-session", "Owned login-session lifecycle (requires native/system mode)");
    parser.addOptions({scenarioOption, densityOption, wallpaperOption, sizeOption, ambientOption,
                       developerOption, nativeSurfaceOption, applicationsOption,
                       managedSessionOption});
    parser.addOptions({cropOption, focusOption, lockStateOption, islandStateOption,
                       welcomePageOption, debugGeometryOption, smokeOption, captureOption,
                       viewOption, darkOption, idleOption, localeOption, voiceOption});
    parser.process(app);
    const auto applicationSource = parser.isSet(applicationsOption)
                                       ? parser.value(applicationsOption)
                                   : parser.isSet(nativeSurfaceOption) ? "system"
                                                                       : "mock";
    if (parser.isSet(managedSessionOption) &&
        (!parser.isSet(nativeSurfaceOption) || applicationSource != "system" ||
         qEnvironmentVariable("OWODE_MANAGED_SESSION") != "1")) {
        qCritical()
            << "Managed sessions require the owoDE session launcher and native/system mode.";
        return EXIT_FAILURE;
    }
    if ((applicationSource != "system" && applicationSource != "mock") ||
        (applicationSource == "system" &&
         (!parser.isSet(nativeSurfaceOption) || !klde::DesktopApplicationBackend::available()))) {
        qCritical() << "System applications require native-surface mode and KF6 Service/KIO."
                    << "Use --applications mock for an isolated native visual test.";
        return EXIT_FAILURE;
    }
    if (parser.isSet(nativeSurfaceOption) && parser.isSet(smokeOption)) {
        qCritical() << "--native-shell-surfaces cannot be combined with --smoke-test";
        return EXIT_FAILURE;
    }
    if ((parser.isSet(captureOption) || parser.isSet(idleOption)) && !parser.isSet(smokeOption)) {
        qCritical() << "--capture and --audit-idle require --smoke-test";
        return EXIT_FAILURE;
    }
    if (parser.value(cropOption) != "full" && parser.value(cropOption) != "ribbon") {
        qCritical() << "Invalid capture region";
        return EXIT_FAILURE;
    }
    if (!previewViews.contains(parser.value(viewOption))) {
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
    if (parser.isSet(nativeSurfaceOption)) {
        const klde::NativeSurfaceController surfaceProbe;
        const klde::SessionRuntimeBackend sessionProbe;
        if (!surfaceProbe.available() ||
            !sessionProbe.capabilities().value("kwinService").toBool()) {
            qCritical()
                << "Native surfaces require the linked LayerShellQt Interface, a Wayland QPA"
                << "and the KWin service on the same isolated session bus.";
            return EXIT_FAILURE;
        }
    }
    bool frameHandled = false;
    bool settlingEnabled = false;
    bool auditStarted = false;
    int idleFrames = 0;
    QQmlApplicationEngine engine;
    engine.setProperty("owodeSystemApplications", applicationSource == "system");
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
         {"nativeSurfaceMode", parser.isSet(nativeSurfaceOption)},
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
    if (parser.isSet(managedSessionOption)) {
        auto bus = QDBusConnection::sessionBus();
        if (!services->session()->enableManagedSession() ||
            !bus.registerService("org.owode.Session") ||
            !bus.registerObject("/org/owode/Session", services->session(),
                                QDBusConnection::ExportScriptableSlots)) {
            qCritical() << "Could not own the owoDE session lifecycle; refusing to continue.";
            return EXIT_FAILURE;
        }
        QObject::connect(services->session(), &klde::SessionRuntimeBackend::logoutRequested, &app,
                         &QCoreApplication::quit, Qt::QueuedConnection);
    }
    if (parser.isSet(nativeSurfaceOption)) {
        if (!services->surface()->available() || !services->surface()->hasRole("wallpaper") ||
            !services->surface()->hasRole("ribbon") || !services->surface()->hasRole("dock") ||
            !services->surface()->hasRole("popup")) {
            qCritical() << "Native shell surfaces requested but the LayerShellQt surfaces"
                        << "could not be attached:" << services->surface()->diagnostic();
            return EXIT_FAILURE;
        }
        qInfo() << "owoDE native roles attached: wallpaper, ribbon, dock, dormant popup host";
    }
    if (services->mockScenarios()->activeId() != parser.value(scenarioOption)) {
        qCritical() << "Unknown or invalid mock scenario";
        return EXIT_FAILURE;
    }
    QQuickWindow *graphicsWindow = window;
    if (parser.isSet(nativeSurfaceOption)) {
        for (auto *candidate : QGuiApplication::allWindows()) {
            if (candidate->objectName() == "nativeWallpaperSurface")
                graphicsWindow = qobject_cast<QQuickWindow *>(candidate);
        }
    }
    const QPointer<QQuickWindow> guardedWindow(graphicsWindow);
    QObject::connect(
        graphicsWindow, &QQuickWindow::sceneGraphInitialized, services,
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
        graphicsWindow, &QQuickWindow::sceneGraphInvalidated, services,
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
