// SPDX-License-Identifier: GPL-3.0-or-later
#include "Fcitx5Backend.h"
#include <QDBusArgument>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QStandardPaths>
#include <algorithm>
#include <utility>

namespace {
constexpr auto service = "org.fcitx.Fcitx5";
constexpr auto interface = "org.fcitx.Fcitx.Controller1";
QDBusMessage request(const QString &owner, const char *method, const QVariantList &args = {}) {
    auto message = QDBusMessage::createMethodCall(owner, "/controller", interface, method);
    message.setArguments(args);
    return message;
}
QVariantList decodeMethods(const QVariant &value) {
    if (value.metaType() != QMetaType::fromType<QDBusArgument>())
        return {};
    const auto array = qvariant_cast<QDBusArgument>(value);
    if (array.currentSignature() != "a(sssssssbsa{sv})")
        return {};
    QVariantList result;
    array.beginArray();
    while (!array.atEnd()) {
        QString id, name, nativeName, icon, label, language, addon, layout;
        bool configurable = false;
        QVariantMap options;
        array.beginStructure();
        array >> id >> name >> nativeName >> icon >> label >> language >> addon >> configurable >>
            layout >> options;
        array.endStructure();
        if (result.size() >= 64 || id.isEmpty() || id.size() > 256 || id.contains(QChar::Null))
            continue;
        result.append(
            QVariantMap{{"id", id},
                        {"name", (nativeName.isEmpty() ? name : nativeName).left(128)},
                        {"indicator", (label.isEmpty() ? language : label).toUpper().left(6)}});
    }
    array.endArray();
    return result;
}
} // namespace
namespace klde {
Fcitx5Backend::Fcitx5Backend(QObject *parent)
    : InputMethodBackend(parent), m_bus(QDBusConnection::sessionBus()), m_watcher(this) {
    m_refresh.setSingleShot(true);
    m_refresh.setInterval(50);
    connect(&m_refresh, &QTimer::timeout, this, &Fcitx5Backend::query);
}
void Fcitx5Backend::start() {
    if (m_native)
        return;
    m_native = true;
    m_current.clear();
    emit changed();
    if (!m_bus.isConnected())
        return;
    m_watcher.setConnection(m_bus);
    m_watcher.setWatchMode(QDBusServiceWatcher::WatchForOwnerChange);
    m_watcher.setWatchedServices({service});
    connect(&m_watcher, &QDBusServiceWatcher::serviceOwnerChanged, this,
            [this](const QString &, const QString &, const QString &owner) { setOwner(owner); });
    m_bus.connect(service, "/controller", interface, "InputMethodGroupsChanged", this,
                  SLOT(refresh()));
    auto message = QDBusMessage::createMethodCall("org.freedesktop.DBus", "/org/freedesktop/DBus",
                                                  "org.freedesktop.DBus", "GetNameOwner");
    message.setArguments({service});
    auto *pending = new QDBusPendingCallWatcher(m_bus.asyncCall(message, 2000), this);
    const int generation = m_ownerGeneration;
    connect(pending, &QDBusPendingCallWatcher::finished, this,
            [this, generation](QDBusPendingCallWatcher *call) {
                const QDBusPendingReply<QString> reply = *call;
                if (generation == m_ownerGeneration)
                    setOwner(reply.isError() ? QString{} : reply.value());
                call->deleteLater();
            });
}
void Fcitx5Backend::setOwner(const QString &owner) {
    ++m_ownerGeneration;
    m_owner = owner;
    m_available = !owner.isEmpty();
    m_ready = m_pending = m_refreshAgain = m_switching = false;
    m_refresh.stop();
    m_methods.clear();
    m_current.clear();
    emit changed();
    refresh();
}
void Fcitx5Backend::refresh() {
    if (!m_native || !m_available)
        return;
    if (m_pending) {
        m_refreshAgain = true;
        return;
    }
    if (!m_refresh.isActive())
        m_refresh.start();
}
void Fcitx5Backend::finishQuery(int generation, bool success) {
    if (generation != m_ownerGeneration)
        return;
    m_pending = false;
    m_ready = success;
    if (!success) {
        m_methods.clear();
        m_current.clear();
    }
    emit changed();
    if (std::exchange(m_refreshAgain, false))
        refresh();
}
void Fcitx5Backend::query() {
    if (!m_available || m_pending)
        return;
    m_pending = true;
    const auto generation = m_ownerGeneration;
    auto *pending = new QDBusPendingCallWatcher(
        m_bus.asyncCall(request(m_owner, "FullInputMethodGroupInfo", {QString{}}), 2000), this);
    connect(pending, &QDBusPendingCallWatcher::finished, this,
            [this, generation](QDBusPendingCallWatcher *call) {
                const auto reply = call->reply();
                call->deleteLater();
                if (generation != m_ownerGeneration)
                    return;
                if (reply.type() == QDBusMessage::ErrorMessage ||
                    reply.signature() != "sssa{sv}a(sssssssbsa{sv})") {
                    finishQuery(generation, false);
                    return;
                }
                auto methods = decodeMethods(reply.arguments().at(4));
                auto *current = new QDBusPendingCallWatcher(
                    m_bus.asyncCall(request(m_owner, "CurrentInputMethod"), 2000), this);
                connect(current, &QDBusPendingCallWatcher::finished, this,
                        [this, generation,
                         methods = std::move(methods)](QDBusPendingCallWatcher *call) {
                            const QDBusPendingReply<QString> reply = *call;
                            call->deleteLater();
                            if (generation != m_ownerGeneration)
                                return;
                            if (!reply.isError()) {
                                m_methods = methods;
                                m_current = reply.value().left(256);
                            }
                            finishQuery(generation, !reply.isError() && !m_methods.isEmpty());
                        });
            });
}
QVariantList Fcitx5Backend::methods() const {
    if (m_native)
        return m_methods;
    return {QVariantMap{{"id", "pinyin"}, {"labelId", "input.pinyin"}},
            QVariantMap{{"id", "keyboard-us"}, {"labelId", "input.english"}}};
}
QString Fcitx5Backend::indicator() const {
    if (!m_native)
        return m_current == "pinyin" ? QStringLiteral("拼") : QStringLiteral("EN");
    if (!m_available || m_current.isEmpty())
        return QStringLiteral("—");
    for (const auto &value : m_methods) {
        const auto method = value.toMap();
        if (method.value("id").toString() == m_current) {
            const auto label = method.value("indicator").toString();
            return label.isEmpty() ? m_current.left(6) : label;
        }
    }
    return m_current.left(6);
}
bool Fcitx5Backend::requestSwitch(const QString &id) {
    const bool known = std::any_of(m_methods.cbegin(), m_methods.cend(), [&id](const auto &value) {
        return value.toMap().value("id").toString() == id;
    });
    if (!switchingSupported() || !known)
        return false;
    m_switching = true;
    emit changed();
    const auto generation = m_ownerGeneration;
    auto *pending = new QDBusPendingCallWatcher(
        m_bus.asyncCall(request(m_owner, "SetCurrentIM", {id}), 2000), this);
    connect(pending, &QDBusPendingCallWatcher::finished, pending, &QObject::deleteLater);
    connect(pending, &QDBusPendingCallWatcher::finished, this,
            [this, generation](QDBusPendingCallWatcher *call) {
                const QDBusPendingReply<> reply = *call;
                if (generation != m_ownerGeneration)
                    return;
                m_switching = false;
                if (reply.isError())
                    emit requestRejected(tr("Input method could not be changed"));
                emit changed();
                refresh();
            });
    return true;
}
bool Fcitx5Backend::selectPreview(const QString &id) {
    if (m_native || (id != "pinyin" && id != "keyboard-us"))
        return false;
    if (m_current != id) {
        m_current = id;
        emit changed();
    }
    return true;
}
bool Fcitx5Backend::configure() {
    if (!m_native || !m_available)
        return false;
    if (QStandardPaths::findExecutable(QStringLiteral("fcitx5-configtool")).isEmpty()) {
        emit requestRejected(tr("Fcitx configuration tool is unavailable"));
        return false;
    }
    auto *pending =
        new QDBusPendingCallWatcher(m_bus.asyncCall(request(m_owner, "Configure"), 2000), this);
    connect(pending, &QDBusPendingCallWatcher::finished, pending, &QObject::deleteLater);
    connect(pending, &QDBusPendingCallWatcher::finished, this,
            [this](QDBusPendingCallWatcher *call) {
                const QDBusPendingReply<> reply = *call;
                if (reply.isError())
                    emit requestRejected(tr("Fcitx configuration tool is unavailable"));
            });
    return true;
}
} // namespace klde
