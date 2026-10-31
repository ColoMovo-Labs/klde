// SPDX-License-Identifier: GPL-3.0-or-later
#include "PowerProfilesSource.h"
#include "mock/SystemStateModel.h"
#include <QDBusArgument>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <array>
#include <utility>

namespace {
struct Endpoint {
    const char *service;
    const char *path;
    const char *interface;
};
constexpr std::array<Endpoint, 2> endpoints{
    {{"org.freedesktop.UPower.PowerProfiles", "/org/freedesktop/UPower/PowerProfiles",
      "org.freedesktop.UPower.PowerProfiles"},
     {"net.hadess.PowerProfiles", "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles"}}};
const QString propertiesInterface = QStringLiteral("org.freedesktop.DBus.Properties");

QStringList profileNames(const QVariant &value) {
    QStringList result;
    // Profiles is aa{sv}; QtDBus delivers it demarshalled or as a QDBusArgument.
    QList<QVariantMap> entries;
    if (value.canConvert<QDBusArgument>()) {
        const auto argument = value.value<QDBusArgument>();
        argument >> entries;
    } else {
        for (const auto &entry : value.toList())
            entries.append(entry.toMap());
    }
    for (const auto &entry : std::as_const(entries))
        result.append(entry.value(QStringLiteral("Profile")).toString());
    return result;
}
} // namespace

namespace klde {
PowerProfilesSource::PowerProfilesSource(SystemStateModel *state, QDBusConnection bus,
                                         QObject *parent)
    : QObject(parent), m_state(state), m_bus(std::move(bus)) {
    m_watcher.setConnection(m_bus);
    m_watcher.setWatchMode(QDBusServiceWatcher::WatchForRegistration);
    for (const auto &endpoint : endpoints)
        m_watcher.addWatchedService(QString::fromLatin1(endpoint.service));
    connect(&m_watcher, &QDBusServiceWatcher::serviceRegistered, this, [this](const QString &name) {
        for (int i = 0; i < int(endpoints.size()); ++i)
            if (name == QLatin1String(endpoints.at(i).service) && i <= m_endpoint)
                connectTo(i);
    });
}

void PowerProfilesSource::start() {
    m_state->publishLive(QStringLiteral("capabilities.powerProfiles"), false);
    m_state->setLiveWriter(QStringLiteral("powerProfile"),
                           [this](const QVariant &value) { return request(value.toString()); });
    connectTo(0);
}

void PowerProfilesSource::connectTo(int index) {
    m_endpoint = index;
    const auto &endpoint = endpoints.at(index);
    m_bus.connect(QString::fromLatin1(endpoint.service), QString::fromLatin1(endpoint.path),
                  propertiesInterface, QStringLiteral("PropertiesChanged"), this,
                  SLOT(propertiesChanged(QString, QVariantMap, QStringList)));
    refresh();
}

void PowerProfilesSource::refresh() {
    const auto &endpoint = endpoints.at(m_endpoint);
    auto message = QDBusMessage::createMethodCall(QString::fromLatin1(endpoint.service),
                                                  QString::fromLatin1(endpoint.path),
                                                  propertiesInterface, QStringLiteral("GetAll"));
    message << QString::fromLatin1(endpoint.interface);
    auto *call = new QDBusPendingCallWatcher(m_bus.asyncCall(message), this);
    connect(call, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *self) {
        const QDBusPendingReply<QVariantMap> reply = *self;
        self->deleteLater();
        if (reply.isError()) {
            // Fall back to the older bus name once; otherwise report absence.
            if (m_endpoint + 1 < int(endpoints.size())) {
                connectTo(m_endpoint + 1);
                return;
            }
            m_properties.clear();
            apply(m_properties);
            return;
        }
        m_properties = reply.value();
        apply(m_properties);
    });
}

void PowerProfilesSource::propertiesChanged(const QString &interface, const QVariantMap &changed,
                                            const QStringList &invalidated) {
    if (interface != QLatin1String(endpoints.at(m_endpoint).interface))
        return;
    if (!invalidated.isEmpty()) {
        refresh();
        return;
    }
    for (auto it = changed.cbegin(); it != changed.cend(); ++it)
        m_properties.insert(it.key(), it.value());
    apply(m_properties);
}

void PowerProfilesSource::apply(const QVariantMap &values) {
    m_profiles = profileNames(values.value(QStringLiteral("Profiles")));
    const auto active = values.value(QStringLiteral("ActiveProfile")).toString();
    const bool available = !active.isEmpty();
    if (available)
        m_state->publishLive(QStringLiteral("powerProfile"), active);
    m_state->publishLive(QStringLiteral("capabilities.powerProfiles"), available);
}

bool PowerProfilesSource::request(const QString &profile) {
    if (m_properties.isEmpty() || (!m_profiles.isEmpty() && !m_profiles.contains(profile)))
        return false;
    const auto &endpoint = endpoints.at(m_endpoint);
    auto message = QDBusMessage::createMethodCall(QString::fromLatin1(endpoint.service),
                                                  QString::fromLatin1(endpoint.path),
                                                  propertiesInterface, QStringLiteral("Set"));
    message << QString::fromLatin1(endpoint.interface) << QStringLiteral("ActiveProfile")
            << QVariant::fromValue(QDBusVariant(profile));
    auto *call = new QDBusPendingCallWatcher(m_bus.asyncCall(message), this);
    connect(call, &QDBusPendingCallWatcher::finished, call, &QObject::deleteLater);
    return true;
}
} // namespace klde
