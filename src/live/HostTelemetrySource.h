// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <optional>

namespace klde {
class SystemStateModel;

// Reads CPU load, memory pressure and package temperature from the running
// kernel and publishes them as live state. The root directory is injectable so
// tests can supply a synthetic /proc and /sys tree.
class HostTelemetrySource final : public QObject {
    Q_OBJECT
  public:
    struct CpuTimes {
        quint64 busy = 0;
        quint64 total = 0;
        // Busy share of the interval since an earlier reading, 0-100.
        int usageSince(const CpuTimes &earlier) const;
    };
    explicit HostTelemetrySource(SystemStateModel *state, QString root = QStringLiteral("/"),
                                 QObject *parent = nullptr);
    void start(int intervalMs = 2000);
    void stop() { m_timer.stop(); }
    void sample();

    static std::optional<CpuTimes> parseCpuTimes(const QByteArray &procStat);
    static std::optional<int> parseMemoryUsedPercent(const QByteArray &procMeminfo);
    // Locates a CPU package sensor: coretemp/k10temp/zenpower hwmon first, then
    // an x86_pkg_temp or acpitz thermal zone. Returns the millidegree file path.
    QString findTemperatureInput() const;

  private:
    QByteArray read(const QString &relative) const;
    SystemStateModel *m_state;
    QString m_root;
    QString m_temperatureInput;
    std::optional<CpuTimes> m_previous;
    QTimer m_timer;
};
} // namespace klde
