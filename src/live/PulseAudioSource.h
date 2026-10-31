// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QMetaObject>
#include <QObject>
#include <QPointer>
#include <QTimer>
#include <QtGlobal>

namespace PulseAudioQt {
class Sink;
class Source;
} // namespace PulseAudioQt

namespace klde {
class SystemStateModel;

// Follows the default output and input of PipeWire/PulseAudio through
// pulseaudio-qt. Volume, mute and microphone level are live paths; their
// writers act on whichever device is currently the default.
class PulseAudioSource final : public QObject {
    Q_OBJECT
  public:
    explicit PulseAudioSource(SystemStateModel *state, QObject *parent = nullptr);
    void start();
    // Device volume (normalVolume() == 100%) to a 0-100 percentage, and back.
    static int percent(qint64 volume, qint64 normal);
    static qint64 volumeFor(int percent, qint64 normal);
  signals:
    // A confirmed change of the output volume after the first reading.
    void volumeChanged(int percent);

  private:
    void schedule() { m_refresh.start(); }
    void refresh();
    void follow();
    SystemStateModel *m_state;
    QTimer m_refresh;
    QPointer<PulseAudioQt::Sink> m_sink;
    QPointer<PulseAudioQt::Source> m_source;
    QList<QMetaObject::Connection> m_deviceConnections;
    int m_lastVolume = -1;
};
} // namespace klde
