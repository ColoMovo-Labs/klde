// SPDX-License-Identifier: GPL-3.0-or-later
#include "HostTelemetrySource.h"
#include "mock/SystemStateModel.h"
#include <QDir>
#include <QFile>
#include <QList>
#include <algorithm>
#include <cmath>
#include <utility>

namespace klde {
HostTelemetrySource::HostTelemetrySource(SystemStateModel *state, QString root, QObject *parent)
    : QObject(parent), m_state(state), m_root(std::move(root)) {
    m_timer.setTimerType(Qt::VeryCoarseTimer);
    connect(&m_timer, &QTimer::timeout, this, &HostTelemetrySource::sample);
}

void HostTelemetrySource::start(int intervalMs) {
    m_temperatureInput = findTemperatureInput();
    m_state->publishLive(QStringLiteral("capabilities.sensors"), !m_temperatureInput.isEmpty());
    sample();
    m_timer.start(std::max(intervalMs, 500));
}

QByteArray HostTelemetrySource::read(const QString &relative) const {
    QFile file(QDir(m_root).filePath(relative));
    // Kernel pseudo-files report size 0; read a bounded amount explicitly.
    return file.open(QIODevice::ReadOnly) ? file.read(qint64{64} * 1024) : QByteArray{};
}

std::optional<HostTelemetrySource::CpuTimes>
HostTelemetrySource::parseCpuTimes(const QByteArray &procStat) {
    const auto line = procStat.left(procStat.indexOf('\n')).simplified();
    const auto fields = line.split(' ');
    // cpu user nice system idle iowait irq softirq steal [guest guest_nice]
    if (fields.size() < 5 || fields.constFirst() != "cpu")
        return std::nullopt;
    QList<quint64> values;
    for (qsizetype i = 1; i < std::min<qsizetype>(fields.size(), 9); ++i) {
        bool ok = false;
        values.append(fields.at(i).toULongLong(&ok));
        if (!ok)
            return std::nullopt;
    }
    CpuTimes result;
    for (const auto value : std::as_const(values))
        result.total += value;
    const quint64 idle = values.at(3) + (values.size() > 4 ? values.at(4) : 0);
    result.busy = result.total - std::min(idle, result.total);
    return result;
}

std::optional<int> HostTelemetrySource::parseMemoryUsedPercent(const QByteArray &procMeminfo) {
    std::optional<quint64> total, available;
    for (const auto &raw : procMeminfo.split('\n')) {
        const auto parts = raw.simplified().split(' ');
        if (parts.size() < 2)
            continue;
        bool ok = false;
        const auto kib = parts.at(1).toULongLong(&ok);
        if (!ok)
            continue;
        if (parts.constFirst() == "MemTotal:")
            total = kib;
        else if (parts.constFirst() == "MemAvailable:")
            available = kib;
    }
    if (!total || !available || *total == 0 || *available > *total)
        return std::nullopt;
    return static_cast<int>(std::lround(100.0 * static_cast<double>(*total - *available) /
                                        static_cast<double>(*total)));
}

int HostTelemetrySource::CpuTimes::usageSince(const CpuTimes &earlier) const {
    if (total <= earlier.total || busy < earlier.busy)
        return 0;
    const auto busyDelta = static_cast<double>(busy - earlier.busy);
    const auto totalDelta = static_cast<double>(total - earlier.total);
    return std::clamp(static_cast<int>(std::lround(100.0 * busyDelta / totalDelta)), 0, 100);
}

QString HostTelemetrySource::findTemperatureInput() const {
    const QDir hwmon(QDir(m_root).filePath(QStringLiteral("sys/class/hwmon")));
    for (const auto &entry : hwmon.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
        const auto name = read(QStringLiteral("sys/class/hwmon/%1/name").arg(entry)).trimmed();
        if (name != "coretemp" && name != "k10temp" && name != "zenpower")
            continue;
        const QString base = QStringLiteral("sys/class/hwmon/%1/").arg(entry);
        // Prefer the package/Tctl channel; fall back to the first input.
        for (int channel = 1; channel <= 32; ++channel) {
            const auto label = read(base + QStringLiteral("temp%1_label").arg(channel)).trimmed();
            if (label.startsWith("Package") || label == "Tctl" || label == "Tdie")
                return base + QStringLiteral("temp%1_input").arg(channel);
        }
        if (!read(base + QStringLiteral("temp1_input")).isEmpty())
            return base + QStringLiteral("temp1_input");
    }
    const QDir thermal(QDir(m_root).filePath(QStringLiteral("sys/class/thermal")));
    for (const auto &preferred : {QByteArrayLiteral("x86_pkg_temp"), QByteArrayLiteral("acpitz")}) {
        for (const auto &entry :
             thermal.entryList({QStringLiteral("thermal_zone*")}, QDir::Dirs, QDir::Name)) {
            const QString base = QStringLiteral("sys/class/thermal/%1/").arg(entry);
            if (read(base + QStringLiteral("type")).trimmed() == preferred)
                return base + QStringLiteral("temp");
        }
    }
    return {};
}

void HostTelemetrySource::sample() {
    if (const auto times = parseCpuTimes(read(QStringLiteral("proc/stat")))) {
        if (m_previous)
            m_state->publishLive(QStringLiteral("cpu.usage"), times->usageSince(*m_previous));
        m_previous = times;
    }
    if (const auto memory = parseMemoryUsedPercent(read(QStringLiteral("proc/meminfo"))))
        m_state->publishLive(QStringLiteral("memory.usedPercent"), *memory);
    if (!m_temperatureInput.isEmpty()) {
        bool ok = false;
        const auto milli = read(m_temperatureInput).trimmed().toLongLong(&ok);
        if (ok)
            m_state->publishLive(
                QStringLiteral("cpu.temperature"),
                std::clamp(static_cast<int>(std::lround(static_cast<double>(milli) / 1000.0)), 0,
                           120));
    }
}
} // namespace klde
