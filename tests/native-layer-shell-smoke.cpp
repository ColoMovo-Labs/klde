// SPDX-License-Identifier: GPL-3.0-or-later

#include "platform/wayland/NativeSurfaceController.h"
#include <QCommandLineParser>
#include <QGuiApplication>
#include <QTimer>
#include <QWindow>

int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("klde-layer-shell-smoke"));

    QCommandLineParser parser;
    parser.addHelpOption();
    const QCommandLineOption roleOption(QStringLiteral("role"),
                                        QStringLiteral("Layer role: wallpaper, ribbon or dock"),
                                        QStringLiteral("role"), QStringLiteral("ribbon"));
    const QCommandLineOption holdOption(QStringLiteral("hold-ms"),
                                        QStringLiteral("Keep the surface mapped for this duration"),
                                        QStringLiteral("milliseconds"), QStringLiteral("2500"));
    parser.addOption(roleOption);
    parser.addOption(holdOption);
    parser.process(app);

    bool holdOk = false;
    const int holdMs = parser.value(holdOption).toInt(&holdOk);
    if (!holdOk || holdMs < 100 || holdMs > 120000) {
        qCritical("--hold-ms must be between 100 and 120000");
        return 2;
    }

    QWindow window;
    window.setTitle(QStringLiteral("owoDE LayerShellQt smoke: %1").arg(parser.value(roleOption)));
    window.resize(parser.value(roleOption) == QStringLiteral("wallpaper") ? QSize(1, 1)
                                                                          : QSize(960, 96));
    klde::NativeSurfaceController controller;
    if (!controller.attach(&window, parser.value(roleOption))) {
        qCritical("LayerShellQt could not create the requested surface");
        return 3;
    }
    qInfo().noquote() << "configured role=" << parser.value(roleOption)
                      << "wayland=" << QGuiApplication::platformName() << "size=" << window.size();
    window.show();
    QTimer::singleShot(holdMs, &app, &QCoreApplication::quit);
    return app.exec();
}
