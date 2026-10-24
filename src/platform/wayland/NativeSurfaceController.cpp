// SPDX-License-Identifier: GPL-3.0-or-later
#include "NativeSurfaceController.h"

#include <QGuiApplication>
#include <QPainterPath>
#include <QPointer>
#include <QQuickItem>
#include <QQuickWindow>
#include <QTimer>
#include <QVariant>
#include <QWindow>

#if defined(OWODE_HAVE_LAYERSHELLQT)
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
        m_diagnostic =
            QStringLiteral("LayerShellQt is available; no native surfaces are attached.");
}

bool NativeSurfaceController::compiledIn() const {
#if defined(OWODE_HAVE_LAYERSHELLQT)
    return true;
#else
    return false;
#endif
}

bool NativeSurfaceController::wayland() const { return isWaylandPlatform(); }

bool NativeSurfaceController::available() const { return compiledIn() && wayland(); }

bool NativeSurfaceController::supportsRole(const QString &role) const {
    return role == QStringLiteral("wallpaper") || role == QStringLiteral("ribbon") ||
           role == QStringLiteral("dock") || role == QStringLiteral("popup");
}

bool NativeSurfaceController::hasRole(const QString &role) const {
    return m_roles.values().contains(role);
}

void NativeSurfaceController::queueInputRegion(QWindow *window) {
    if (m_pendingRegions.contains(window))
        return;
    m_pendingRegions.insert(window);
    const QPointer<QWindow> guarded(window);
    QTimer::singleShot(0, this, [this, guarded] {
        if (guarded) {
            m_pendingRegions.remove(guarded.data());
            if (m_roles.contains(guarded.data()))
                updateInputRegion(guarded);
        }
    });
}

void NativeSurfaceController::observeInputTree(QQuickItem *item, QWindow *window) {
    if (!m_observedItems.contains(item)) {
        m_observedItems.insert(item);
        const QPointer<QWindow> guarded(window);
        const auto dirty = [this, guarded] {
            if (guarded)
                queueInputRegion(guarded);
        };
        connect(item, &QQuickItem::xChanged, this, dirty);
        connect(item, &QQuickItem::yChanged, this, dirty);
        connect(item, &QQuickItem::widthChanged, this, dirty);
        connect(item, &QQuickItem::heightChanged, this, dirty);
        connect(item, &QQuickItem::visibleChanged, this, dirty);
        connect(item, &QQuickItem::scaleChanged, this, dirty);
        connect(item, &QQuickItem::childrenChanged, this, [this, item, guarded] {
            if (guarded) {
                observeInputTree(item, guarded);
                queueInputRegion(guarded);
            }
        });
        connect(item, &QObject::destroyed, this, [this, item, dirty] {
            m_observedItems.remove(item);
            dirty();
        });
    }
    for (auto *child : item->childItems())
        observeInputTree(child, window);
}

void NativeSurfaceController::updateInputRegion(QWindow *window) {
    auto *quick = qobject_cast<QQuickWindow *>(window);
    if (!quick)
        return;
    QRegion region;
    const auto collect = [&](auto &&self, QQuickItem *item) -> void {
        if (!item->isVisible())
            return;
        if (item->property("nativeInputSurface").toBool()) {
            const auto rectangle = item->mapRectToScene(item->boundingRect());
            const auto radius = item->property("cornerRadius").isValid()
                                    ? item->property("cornerRadius").toReal()
                                    : rectangle.height() / 2;
            QPainterPath path;
            path.addRoundedRect(rectangle, radius, radius);
            region += QRegion(path.toFillPolygon().toPolygon());
            return;
        }
        for (auto *child : item->childItems())
            self(self, child);
    };
    collect(collect, quick->contentItem());
    region &= QRect(QPoint(), window->size());
    // An empty QWindow mask means "unrestricted", not "no input". Use the
    // public transparent-input flag while a section contains no controls.
    window->setFlag(Qt::WindowTransparentForInput, region.isEmpty());
    if (window->mask() != region)
        window->setMask(region);
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
    if (m_roles.contains(window))
        return m_roles.value(window) == role;
    if (window->isVisible()) {
        setDiagnostic(QStringLiteral("Native roles must be attached before showing the window."));
        return false;
    }
    if (!available()) {
        setDiagnostic(
            compiledIn()
                ? QStringLiteral("LayerShellQt is present but the current QPA is not Wayland.")
                : QStringLiteral("LayerShellQt is unavailable; native surface role '%1' is gated.")
                      .arg(role));
        return false;
    }

#if defined(OWODE_HAVE_LAYERSHELLQT)
    // Qt 6.5+ selects the layer-shell client integration automatically when a
    // LayerShellQt Window is requested. The target Fedora/KWin package is
    // expected to provide that supported path; no private Qt API is used here.
    auto *surface = LayerShellQt::Window::get(window);
    if (surface == nullptr) {
        setDiagnostic(QStringLiteral("LayerShellQt did not create a surface for '%1'.").arg(role));
        return false;
    }

    window->setFlag(Qt::FramelessWindowHint, true);
    surface->setScope(QStringLiteral("owode-%1").arg(role));
    surface->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
    surface->setActivateOnShow(role == QStringLiteral("popup"));
    surface->setCloseOnDismissed(true);
    surface->setWantsToBeOnActiveScreen(false);
    surface->setScreen(window->screen());

    if (role == QStringLiteral("wallpaper")) {
        surface->setLayer(LayerShellQt::Window::LayerBackground);
        surface->setAnchors({LayerShellQt::Window::AnchorTop, LayerShellQt::Window::AnchorBottom,
                             LayerShellQt::Window::AnchorLeft, LayerShellQt::Window::AnchorRight});
        surface->setMargins(QMargins());
        // Wallpaper spans the whole output, including underneath reserved panels.
        surface->setExclusiveZone(-1);
        // The background must never steal clicks from application windows.
        window->setFlag(Qt::WindowTransparentForInput, true);
    } else if (role == QStringLiteral("ribbon")) {
        surface->setLayer(LayerShellQt::Window::LayerTop);
        surface->setAnchors({LayerShellQt::Window::AnchorTop, LayerShellQt::Window::AnchorLeft,
                             LayerShellQt::Window::AnchorRight});
        // QML owns the visual margin; applying it here as well doubles it.
        surface->setMargins(QMargins());
        surface->setExclusiveZone(window->height());
        surface->setExclusiveEdge(LayerShellQt::Window::AnchorTop);
        connect(window, &QWindow::heightChanged, surface,
                [surface](int height) { surface->setExclusiveZone(height); });
    } else if (role == QStringLiteral("dock")) {
        surface->setLayer(LayerShellQt::Window::LayerTop);
        surface->setAnchors({LayerShellQt::Window::AnchorBottom, LayerShellQt::Window::AnchorLeft,
                             LayerShellQt::Window::AnchorRight});
        surface->setMargins(QMargins());
        surface->setExclusiveZone(0);
    } else {
        surface->setLayer(LayerShellQt::Window::LayerOverlay);
        surface->setAnchors({LayerShellQt::Window::AnchorTop, LayerShellQt::Window::AnchorBottom,
                             LayerShellQt::Window::AnchorLeft, LayerShellQt::Window::AnchorRight});
        surface->setMargins(QMargins());
        surface->setExclusiveZone(-1);
        // This surface is mapped only while a dismissible shell popup is open.
        // Unmapping it releases keyboard focus back to normal applications.
        surface->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
    }
    m_roles.insert(window, role);
    connect(window, &QObject::destroyed, this, [this, window] {
        m_roles.remove(window);
        m_pendingRegions.remove(window);
        emit changed();
    });
    if (role == QStringLiteral("ribbon") || role == QStringLiteral("dock")) {
        if (auto *quick = qobject_cast<QQuickWindow *>(window)) {
            observeInputTree(quick->contentItem(), window);
            updateInputRegion(window);
            connect(window, &QWindow::visibleChanged, this,
                    [this, window] { queueInputRegion(window); });
        }
    }
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
