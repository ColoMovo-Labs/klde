// SPDX-License-Identifier: GPL-3.0-or-later
#include "PulseAudioSource.h"
#include "mock/SystemStateModel.h"
#include <PulseAudioQt/Context>
#include <PulseAudioQt/Server>
#include <PulseAudioQt/Sink>
#include <PulseAudioQt/Source>
#include <algorithm>
#include <cmath>

namespace klde {
PulseAudioSource::PulseAudioSource(SystemStateModel *state, QObject *parent)
    : QObject(parent), m_state(state) {
    m_refresh.setSingleShot(true);
    m_refresh.setInterval(0);
    connect(&m_refresh, &QTimer::timeout, this, &PulseAudioSource::refresh);
}

int PulseAudioSource::percent(qint64 volume, qint64 normal) {
    if (normal <= 0)
        return 0;
    return std::clamp(static_cast<int>(std::lround(100.0 * static_cast<double>(volume) /
                                                   static_cast<double>(normal))),
                      0, 100);
}

qint64 PulseAudioSource::volumeFor(int percent, qint64 normal) {
    return std::llround(static_cast<double>(normal) * std::clamp(percent, 0, 100) / 100.0);
}

void PulseAudioSource::start() {
    // Without a sound server the controls are unavailable, not a fixture.
    m_state->publishLive(QStringLiteral("capabilities.microphone"), false);
    m_state->publishLive(QStringLiteral("audio.volume"), 0);
    m_state->publishLive(QStringLiteral("audio.muted"), true);
    m_state->publishLive(QStringLiteral("audio.microphone"), 0);
    m_state->publishLive(QStringLiteral("audio.microphoneMuted"), true);
    m_state->setLiveWriter(QStringLiteral("audio.volume"), [this](const QVariant &value) {
        if (!m_sink)
            return false;
        const int level = value.toInt();
        m_sink->setVolume(volumeFor(level, PulseAudioQt::normalVolume()));
        if (level > 0 && m_sink->isMuted())
            m_sink->setMuted(false);
        return true;
    });
    m_state->setLiveWriter(QStringLiteral("audio.muted"), [this](const QVariant &value) {
        if (!m_sink)
            return false;
        m_sink->setMuted(value.toBool());
        return true;
    });
    m_state->setLiveWriter(QStringLiteral("audio.microphone"), [this](const QVariant &value) {
        if (!m_source)
            return false;
        const int level = value.toInt();
        // Quick Settings mutes the microphone by requesting level 0.
        if (level == 0) {
            m_source->setMuted(true);
        } else {
            m_source->setVolume(volumeFor(level, PulseAudioQt::normalVolume()));
            m_source->setMuted(false);
        }
        return true;
    });
    m_state->setLiveWriter(QStringLiteral("audio.microphoneMuted"), [this](const QVariant &value) {
        if (!m_source)
            return false;
        m_source->setMuted(value.toBool());
        return true;
    });
    auto *server = PulseAudioQt::Context::instance()->server();
    connect(server, &PulseAudioQt::Server::defaultSinkChanged, this, &PulseAudioSource::follow);
    connect(server, &PulseAudioQt::Server::defaultSourceChanged, this, &PulseAudioSource::follow);
    follow();
}

void PulseAudioSource::follow() {
    for (const auto &connection : std::as_const(m_deviceConnections))
        disconnect(connection);
    m_deviceConnections.clear();
    auto *server = PulseAudioQt::Context::instance()->server();
    m_sink = server->defaultSink();
    m_source = server->defaultSource();
    const QList<PulseAudioQt::VolumeObject *> devices{m_sink.data(), m_source.data()};
    for (auto *device : devices) {
        if (!device)
            continue;
        m_deviceConnections.append(connect(device, &PulseAudioQt::VolumeObject::volumeChanged, this,
                                           &PulseAudioSource::schedule));
        m_deviceConnections.append(connect(device, &PulseAudioQt::VolumeObject::mutedChanged, this,
                                           &PulseAudioSource::schedule));
    }
    schedule();
}

void PulseAudioSource::refresh() {
    const auto normal = PulseAudioQt::normalVolume();
    if (m_sink) {
        const int volume = percent(m_sink->volume(), normal);
        m_state->publishLive(QStringLiteral("audio.volume"), volume);
        m_state->publishLive(QStringLiteral("audio.muted"), m_sink->isMuted());
        if (m_lastVolume >= 0 && volume != m_lastVolume)
            emit volumeChanged(volume);
        m_lastVolume = volume;
    }
    // A monitor of an output is not a microphone.
    const bool microphone = m_source && !m_source->name().endsWith(QLatin1String(".monitor"));
    m_state->publishLive(QStringLiteral("capabilities.microphone"), microphone);
    if (microphone) {
        const bool muted = m_source->isMuted();
        m_state->publishLive(QStringLiteral("audio.microphoneMuted"), muted);
        m_state->publishLive(QStringLiteral("audio.microphone"),
                             muted ? 0 : percent(m_source->volume(), normal));
    }
}
} // namespace klde
