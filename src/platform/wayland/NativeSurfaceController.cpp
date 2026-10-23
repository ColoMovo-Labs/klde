// SPDX-License-Identifier: GPL-3.0-or-later
#include "NativeSurfaceController.h"

#include <QGuiApplication>
#include <QPointer>
#include <QWindow>

#if defined(LOMODE_HAVE_LAYERSHELLQT)
#include <LayerShellQt/Window>
#endif

namespace klde {

namespace {
bool isWaylandPlatform() {
    const auto platform = QGuiApplication::platformName();
    return platform.startsWith(QStringLiteral("wayland"));
}
} // namespace

NativeSurfaceController::NativeSurfaceController(QObject *parent) : QObject(parent) {
    if (!compiledIn())
        m_diagnostic = QStringLiteral("LayerShellQt was not found at configure time.");
    else if (!wayland())
        m_diagnostic = QStringLiteral("Native shell surfaces require a Wayland QPA platform.");
    else
        m_diagnostic = QStringLiteral("LayerShellQt is available; no native surfaces are attached.");
}

bool NativeSurfaceController::compiledIn() const {
#if defined(LOMODE_HAVE_LAYERSHELLQT)
    return true;
#else
    return false;
#endif
}

bool NativeSurfaceController::wayland() const { return isWaylandPlatform(); }

bool NativeSurfaceController::available() const { return compiledIn() && wayland(); }

bool NativeSurfaceController::supportsRole(const QString &role) const {
    return role == QStringLiteral("wallpaper") || role == QStringLiteral("ribbon") ||
           role == QStringLiteral("dock");
}

void NativeSurfaceController::setDiagnostic(const QString &diagnostic) {
    if (m_diagnostic == diagnostic)
        return;
    m_diagnostic = diagnostic;
    emit changed();
}

bool NativeSurfaceController::attach(QObject *object, const QString &role) {
    auto *window = qobject_cast<QWindow *>(object);
    if (window == nullptr) {
        setDiagnostic(QStringLiteral("Native surface attachment requires a QWindow."));
        return false;
    }
    if (!supportsRole(role)) {
        setDiagnostic(QStringLiteral("Unsupported native surface role: %1").arg(role));
        return false;
    }
    if (!available()) {
        setDiagnostic(compiledIn()
                          ? QStringLiteral("LayerShellQt is present but the current QPA is not Wayland.")
                          : QStringLiteral("LayerShellQt is unavailable; native surface role '%1' is gated.")
                                .arg(role));
        return false;
    }

#if defined(LOMODE_HAVE_LAYERSHELLQT)
    // Qt 6.5+ selects the layer-shell client integration automatically when a
    // LayerShellQt Window is requested. The target Fedora/KWin package is
    // expected to provide that supported path; no private Qt API is used here.
    auto *surface = LayerShellQt::Window::get(window);
    if (surface == nullptr) {
        setDiagnostic(QStringLiteral("LayerShellQt did not create a surface for '%1'.").arg(role));
        return false;
    }

    window->setFlag(Qt::FramelessWindowHint, true);
    surface->setScope(QStringLiteral("lomode-%1").arg(role));
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
        surface->setMargins(QMargins());
        surface->setExclusiveZone(0);
        // The background must never steal clicks from application windows.
        window->setFlag(Qt::WindowTransparentForInput, true);
    } else if (role == QStringLiteral("ribbon")) {
        surface->setLayer(LayerShellQt::Window::LayerTop);
        surface->setAnchors({LayerShellQt::Window::AnchorTop,
                             LayerShellQt::Window::AnchorLeft,
                             LayerShellQt::Window::AnchorRight});
        surface->setMargins(QMargins(16, 16, 16, 0));
        surface->setExclusiveZone(window->height() + 16);
        surface->setExclusiveEdge(LayerShellQt::Window::AnchorTop);
    } else {
        surface->setLayer(LayerShellQt::Window::LayerTop);
        surface->setAnchors({LayerShellQt::Window::AnchorBottom,
                             LayerShellQt::Window::AnchorLeft,
                             LayerShellQt::Window::AnchorRight});
        surface->setMargins(QMargins(0, 0, 0, 24));
        surface->setExclusiveZone(0);
    }
    ++m_attachedSurfaceCount;
    setDiagnostic(QStringLiteral("Attached native LayerShellQt surface '%1'.").arg(role));
    emit changed();
    return true;
#else
    Q_UNUSED(window)
    Q_UNUSED(role)
    return false;
#endif
}

} // namespace klde
