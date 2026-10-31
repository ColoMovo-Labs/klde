// SPDX-License-Identifier: GPL-3.0-or-later
#include "BrightnessSource.h"
#include "mock/SystemStateModel.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDir>
#include <QFile>
#include <algorithm>
#include <cmath>
#include <utility>

namespace klde {
BrightnessSource::BrightnessSource(SystemStateModel *state, QString root, QObject *parent)
    : QObject(parent), m_state(state), m_root(std::move(root)) {
    m_poll.setTimerType(Qt::VeryCoarseTimer);
    connect(&m_poll, &QTimer::timeout, this, &BrightnessSource::sample);
}

int BrightnessSource::readInt(const QString &file) const {
    QFile input(QDir(m_root).filePath(file));
    bool ok = false;
    const int value = input.open(QIODevice::ReadOnly) ? input.read(64).trimmed().toInt(&ok) : 0;
    return ok ? value : -1;
}

QString BrightnessSource::findDevice() const {
    const QDir backlight(QDir(m_root).filePath(QStringLiteral("sys/class/backlight")));
    const auto entries = backlight.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const auto *type : {"firmware", "platform", "raw"}) {
        for (const auto &entry : entries) {
            QFile file(backlight.filePath(entry + QStringLiteral("/type")));
            if (file.open(QIODevice::ReadOnly) && file.read(32).trimmed() == type &&
                readInt(QStringLiteral("sys/class/backlight/%1/max_brightness").arg(entry)) > 0)
                return entry;
        }
    }
    return {};
}

int BrightnessSource::percent(int brightness, int maximum) {
    if (maximum <= 0 || brightness < 0)
        return 0;
    return std::clamp(static_cast<int>(std::lround(100.0 * brightness / maximum)), 0, 100);
}

int BrightnessSource::rawFor(int percent, int maximum) {
    // Never write 0: on many panels that switches the backlight fully off.
    return std::clamp(static_cast<int>(std::lround(maximum * std::clamp(percent, 1, 100) / 100.0)),
                      1, std::max(maximum, 1));
}

void BrightnessSource::start(int pollMs) {
    m_device = findDevice();
    m_maximum =
        m_device.isEmpty()
            ? 0
            : readInt(QStringLiteral("sys/class/backlight/%1/max_brightness").arg(m_device));
    m_state->publishLive(QStringLiteral("capabilities.brightness"), m_maximum > 0);
    m_state->setLiveWriter(QStringLiteral("brightness"),
                           [this](const QVariant &value) { return request(value.toInt()); });
    if (m_maximum <= 0)
        return;
    sample();
    m_poll.start(std::max(pollMs, 500));
}

void BrightnessSource::sample() {
    const int raw = readInt(QStringLiteral("sys/class/backlight/%1/brightness").arg(m_device));
    if (raw < 0)
        return;
    const int value = percent(raw, m_maximum);
    m_state->publishLive(QStringLiteral("brightness"), value);
    if (m_last >= 0 && value != m_last)
        emit brightnessChanged(value);
    m_last = value;
}

bool BrightnessSource::request(int percent) {
    if (m_maximum <= 0)
        return false;
    auto message = QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.login1"),
        QStringLiteral("/org/freedesktop/login1/session/auto"),
        QStringLiteral("org.freedesktop.login1.Session"), QStringLiteral("SetBrightness"));
    message << QStringLiteral("backlight") << m_device
            << static_cast<uint>(rawFor(percent, m_maximum));
    auto *call = new QDBusPendingCallWatcher(QDBusConnection::systemBus().asyncCall(message), this);
    connect(call, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *self) {
        self->deleteLater();
        sample();
    });
    return true;
}
} // namespace klde
