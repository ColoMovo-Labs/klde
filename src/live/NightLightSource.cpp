// SPDX-License-Identifier: GPL-3.0-or-later
#include "NightLightSource.h"
#include "mock/SystemStateModel.h"
#include <KConfigGroup>
#include <KSharedConfig>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <utility>

namespace {
const QString service = QStringLiteral("org.kde.KWin");
const QString path = QStringLiteral("/org/kde/KWin/NightLight");
const QString interface = QStringLiteral("org.kde.KWin.NightLight");
const QString properties = QStringLiteral("org.freedesktop.DBus.Properties");
} // namespace

namespace klde {
NightLightSource::NightLightSource(SystemStateModel *state, QDBusConnection bus, QObject *parent)
    : QObject(parent), m_state(state), m_bus(std::move(bus)),
      m_watcher(service, m_bus, QDBusServiceWatcher::WatchForRegistration) {
    connect(&m_watcher, &QDBusServiceWatcher::serviceRegistered, this, &NightLightSource::refresh);
}

void NightLightSource::start() {
    m_state->publishLive(QStringLiteral("capabilities.nightLight"), false);
    m_state->publishLive(QStringLiteral("nightMode"), false);
    m_state->setLiveWriter(QStringLiteral("nightMode"),
                           [this](const QVariant &value) { return request(value.toBool()); });
    m_bus.connect(service, path, properties, QStringLiteral("PropertiesChanged"), this,
                  SLOT(propertiesChanged(QString, QVariantMap, QStringList)));
    refresh();
}

void NightLightSource::refresh() {
    auto message =
        QDBusMessage::createMethodCall(service, path, properties, QStringLiteral("GetAll"));
    message << interface;
    auto *call = new QDBusPendingCallWatcher(m_bus.asyncCall(message), this);
    connect(call, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *self) {
        const QDBusPendingReply<QVariantMap> reply = *self;
        self->deleteLater();
        m_properties = reply.isError() ? QVariantMap{} : reply.value();
        apply(m_properties);
    });
}

void NightLightSource::propertiesChanged(const QString &changedInterface,
                                         const QVariantMap &changed,
                                         const QStringList &invalidated) {
    if (changedInterface != interface)
        return;
    if (!invalidated.isEmpty()) {
        refresh();
        return;
    }
    for (auto it = changed.cbegin(); it != changed.cend(); ++it)
        m_properties.insert(it.key(), it.value());
    apply(m_properties);
}

void NightLightSource::apply(const QVariantMap &values) {
    const bool available = values.value(QStringLiteral("available")).toBool();
    m_state->publishLive(QStringLiteral("capabilities.nightLight"), available);
    m_state->publishLive(QStringLiteral("nightMode"),
                         available && values.value(QStringLiteral("enabled")).toBool());
}

bool NightLightSource::request(bool enabled) {
    if (!m_properties.value(QStringLiteral("available")).toBool())
        return false;
    KConfigGroup group(KSharedConfig::openConfig(QStringLiteral("kwinrc")),
                       QStringLiteral("NightColor"));
    group.writeEntry("Active", enabled);
    // The quick switch means "warm now", independent of the time schedule.
    if (enabled)
        group.writeEntry("Mode", QStringLiteral("Constant"));
    if (!group.sync())
        return false;
    const auto message = QDBusMessage::createMethodCall(service, QStringLiteral("/KWin"),
                                                        QStringLiteral("org.kde.KWin"),
                                                        QStringLiteral("reconfigure"));
    auto *call = new QDBusPendingCallWatcher(m_bus.asyncCall(message), this);
    connect(call, &QDBusPendingCallWatcher::finished, call, &QObject::deleteLater);
    return true;
}
} // namespace klde
