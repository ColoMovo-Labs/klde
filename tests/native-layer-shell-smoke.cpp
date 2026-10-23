// SPDX-License-Identifier: GPL-3.0-or-later

#include <LayerShellQt/Window>
#include <QCommandLineParser>
#include <QGuiApplication>
#include <QTimer>
#include <QWindow>

namespace {
bool configure(QWindow &window, const QString &role) {
    auto *surface = LayerShellQt::Window::get(&window);
    if (surface == nullptr)
        return false;

    window.setFlag(Qt::FramelessWindowHint, true);
    surface->setScope(QStringLiteral("lomode-smoke-%1").arg(role));
    surface->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
    surface->setActivateOnShow(false);
    surface->setCloseOnDismissed(true);
    surface->setWantsToBeOnActiveScreen(true);

    if (role == QStringLiteral("wallpaper")) {
        surface->setLayer(LayerShellQt::Window::LayerBackground);
        surface->setAnchors({LayerShellQt::Window::AnchorTop,
                             LayerShellQt::Window::AnchorBottom,
                             LayerShellQt::Window::AnchorLeft,
                             LayerShellQt::Window::AnchorRight});
        window.setFlag(Qt::WindowTransparentForInput, true);
    } else if (role == QStringLiteral("ribbon")) {
        surface->setLayer(LayerShellQt::Window::LayerTop);
        surface->setAnchors({LayerShellQt::Window::AnchorTop,
                             LayerShellQt::Window::AnchorLeft,
                             LayerShellQt::Window::AnchorRight});
        surface->setMargins(QMargins(16, 16, 16, 0));
        surface->setExclusiveZone(window.height() + 16);
        surface->setExclusiveEdge(LayerShellQt::Window::AnchorTop);
    } else if (role == QStringLiteral("dock")) {
        surface->setLayer(LayerShellQt::Window::LayerTop);
        surface->setAnchors({LayerShellQt::Window::AnchorBottom,
                             LayerShellQt::Window::AnchorLeft,
                             LayerShellQt::Window::AnchorRight});
        surface->setMargins(QMargins(0, 0, 0, 24));
    } else {
        return false;
    }
    return true;
}
} // namespace

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
    window.setTitle(QStringLiteral("LoMoDE LayerShellQt smoke: %1").arg(parser.value(roleOption)));
    window.resize(parser.value(roleOption) == QStringLiteral("wallpaper") ? QSize(1, 1)
                                                                        : QSize(960, 96));
    if (!configure(window, parser.value(roleOption))) {
        qCritical("LayerShellQt could not create the requested surface");
        return 3;
    }
    qInfo().noquote() << "configured role=" << parser.value(roleOption)
                      << "wayland=" << QGuiApplication::platformName()
                      << "size=" << window.size();
    window.show();
    QTimer::singleShot(holdMs, &app, &QCoreApplication::quit);
    return app.exec();
}
