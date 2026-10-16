// SPDX-License-Identifier: GPL-3.0-or-later
#include "Fcitx5Backend.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>

namespace klde {
Fcitx5Backend::Fcitx5Backend(QObject *parent) : InputMethodBackend(parent) {
    const auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected())
        return;
    const QString service = QStringLiteral("org.fcitx.Fcitx5");
    m_watcher.setConnection(bus);
    m_watcher.setWatchMode(QDBusServiceWatcher::WatchForOwnerChange);
    m_watcher.setWatchedServices({service});
    connect(&m_watcher, &QDBusServiceWatcher::serviceOwnerChanged, this,
            [this](const QString &, const QString &, const QString &owner) {
                ++m_ownerGeneration;
                setAvailable(!owner.isEmpty());
            });
    auto message = QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.DBus"), QStringLiteral("/org/freedesktop/DBus"),
        QStringLiteral("org.freedesktop.DBus"), QStringLiteral("NameHasOwner"));
    message.setArguments({service});
    auto *pending = new QDBusPendingCallWatcher(bus.asyncCall(message), this);
    const int generation = m_ownerGeneration;
    connect(pending, &QDBusPendingCallWatcher::finished, this,
            [this, generation](QDBusPendingCallWatcher *watcher) {
                const QDBusPendingReply<bool> reply = *watcher;
                if (generation == m_ownerGeneration)
                    setAvailable(!reply.isError() && reply.value());
                watcher->deleteLater();
            });
}
void Fcitx5Backend::setAvailable(bool available) {
    if (m_available != available) {
        m_available = available;
        emit changed();
    }
}
QVariantList Fcitx5Backend::methods() const {
    return {QVariantMap{{"id", "pinyin"}, {"labelId", "input.pinyin"}},
            QVariantMap{{"id", "keyboard-us"}, {"labelId", "input.english"}}};
}
bool Fcitx5Backend::requestSwitch(const QString &id) {
    Q_UNUSED(id)
    return false; // Detection does not grant method-control capability.
}
bool Fcitx5Backend::selectPreview(const QString &id) {
    if (id != "pinyin" && id != "keyboard-us")
        return false;
    if (m_current != id) {
        m_current = id;
        emit changed();
    }
    return true;
}
} // namespace klde
