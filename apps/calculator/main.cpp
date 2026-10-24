// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCommandLineParser>
#include <QGuiApplication>
#include <QImage>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QVariant>
#include <QtQml/QQmlExtensionPlugin>
#include <cstdlib>

Q_IMPORT_QML_PLUGIN(OwoCalculatorPlugin)

int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("owode-calculator"));
    app.setOrganizationName(QStringLiteral("owoDE"));
    QQuickStyle::setStyle(QStringLiteral("Basic"));
    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("owoDE Calculator — Lingmo engine adaptation"));
    parser.addHelpOption();
    parser.addOptions(
        {{"dark", "Use dark appearance"},
         {"locale", "Interface language: en or zh_CN", "locale"},
         {"wallpaper", "Shared palette: snow, abstract, quiet or kemono", "wallpaper", "snow"},
         {"smoke-test", "Capture an actual calculator window and exit"},
         {"capture", "Smoke-test PNG path", "path"}});
    parser.process(app);
    if ((!parser.value("locale").isEmpty() && parser.value("locale") != "en" &&
         parser.value("locale") != "zh_CN") ||
        !QStringList{"snow", "abstract", "quiet", "kemono"}.contains(parser.value("wallpaper")) ||
        (parser.isSet("capture") && !parser.isSet("smoke-test")))
        return EXIT_FAILURE;
    app.setProperty("owodeDark", parser.isSet("dark"));
    app.setProperty("owodeLocale", parser.value("locale"));
    app.setProperty("owodeWallpaper", parser.value("wallpaper"));
    bool warnings = false;
    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app, [&] { warnings = true; });
    engine.loadFromModule("OwoDE.Calculator", "Main");
    if (engine.rootObjects().size() != 1)
        return EXIT_FAILURE;
    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (!window)
        return EXIT_FAILURE;
    if (parser.isSet("smoke-test")) {
        const auto capture = parser.value("capture");
        QTimer::singleShot(1200, &app, [&, capture] {
            const auto frame = window->grabWindow();
            app.exit(!warnings && !frame.isNull() && (capture.isEmpty() || frame.save(capture))
                         ? EXIT_SUCCESS
                         : EXIT_FAILURE);
        });
        QTimer::singleShot(10000, &app, [&] { app.exit(EXIT_FAILURE); });
    }
    return app.exec();
}
