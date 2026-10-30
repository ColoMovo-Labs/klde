// SPDX-License-Identifier: GPL-3.0-or-later
#include "PresentationBackends.h"
#include <QDateTime>
#include <QFileInfo>

namespace klde {
SystemTimeBackend::SystemTimeBackend(QObject *parent) : TimeBackend(parent) {
    m_minute.setSingleShot(true);
    m_minute.setTimerType(Qt::PreciseTimer);
    connect(&m_minute, &QTimer::timeout, this, &SystemTimeBackend::refresh);
    connect(&m_zone, &QFileSystemWatcher::fileChanged, this,
            [this](const QString &) { refresh(); });
    refresh();
}

QVariantMap SystemTimeBackend::readingAt(const QDateTime &date) {
    const int hour = date.time().hour();
    const bool night = hour < 6 || hour >= 19;
    const auto phase = night       ? "starry-night"
                       : hour < 11 ? "clear-morning"
                       : hour < 17 ? "cloudy-day"
                                   : "sunset";
    // The landscape is illustration, not an inferred weather/ephemeris reading.
    // Language selection never supplies a region, hemisphere or weather location.
    return {{"dateTime", date.toString(Qt::ISODate)},
            {"timeText", date.time().toString("HH:mm")},
            {"hours", date.time().toString("HH")},
            {"minutes", date.time().toString("mm")},
            {"phase", phase},
            {"season", "unavailable"},
            {"night", night},
            {"weatherAvailable", false},
            {"weatherMood", "unknown"},
            {"sunVisible", false},
            {"moonVisible", false},
            {"sunX", 0.25},
            {"sunY", 0.34},
            {"moonX", 0.25},
            {"moonY", 0.34},
            {"astronomy", QVariantMap{{"available", false},
                                      {"simulated", false},
                                      {"sunrise", "—"},
                                      {"sunset", "—"},
                                      {"moonrise", "—"},
                                      {"moonset", "—"},
                                      {"moonPhase", "unknown"}}},
            {"mock", false}};
}

void SystemTimeBackend::refresh() {
    const auto current = QDateTime::currentDateTime();
    const auto next = readingAt(current);
    if (next != m_reading) {
        m_reading = next;
        emit changed();
    }
    // One wake per visible minute, not a seconds-based repaint loop. Re-read
    // wall time after resume and on timezone-file replacement, then realign.
    const auto milliseconds = QDateTime::currentMSecsSinceEpoch();
    m_minute.start(static_cast<int>(60000 - milliseconds % 60000));
    for (const auto &path : {QStringLiteral("/etc/localtime"), QStringLiteral("/etc/timezone")}) {
        if (QFileInfo::exists(path) && !m_zone.files().contains(path))
            m_zone.addPath(path);
    }
}

MockTimeBackend::MockTimeBackend(SystemStateModel *state) : m_state(state) {
    connect(state, &SystemStateModel::changed, this, &TimeBackend::changed);
}
QVariantMap MockTimeBackend::reading() const {
    const auto date = QDateTime::fromString(m_state->value("time").toString(), Qt::ISODate);
    const auto hour = date.time().hour();
    auto phase = m_state->value("temporal.phase").toString();
    const auto weather = m_state->value("weather.condition").toString();
    if (phase == "auto") {
        const bool wetWeather = weather == "rain" || weather == "thunderstorm" || weather == "snow";
        const bool overcastWeather =
            weather == "partly-cloudy" || weather == "cloudy" || weather == "fog";
        if (hour < 6 || hour >= 19)
            phase = weather == "clear" ? "starry-night" : "moonlit-night";
        else if (hour < 11)
            phase = wetWeather ? "rainy-evening" : overcastWeather ? "cloudy-day" : "clear-morning";
        else if (hour < 17)
            phase = wetWeather ? "rainy-evening" : "cloudy-day";
        else
            phase = wetWeather ? "rainy-evening" : "sunset";
    }
    // Synthetic ephemeris: separate moon visibility, never inferred merely from night.
    const QTime sunrise(6, 20), sunset(18, 10), moonrise(23, 10), moonset(10, 40);
    const auto time = date.time();
    const bool moonAboveHorizon = time >= moonrise || time < moonset;
    const bool manualPhase = m_state->value("temporal.phase") != "auto";
    const bool sunVisible = phase == "clear-morning" || phase == "cloudy-day" || phase == "sunset";
    const bool moonVisible = phase == "moonlit-night" && (manualPhase || moonAboveHorizon);
    // Quantized to 15 minutes. A minute tick updates text, not the cached SVGs.
    const int sampledMinutes = hour * 60 + time.minute() / 15 * 15;
    const double dayProgress = qBound(0.0, (sampledMinutes - 380) / 710.0, 1.0);
    const int month = date.date().month();
    const auto season = month >= 3 && month <= 5    ? "spring"
                        : month >= 6 && month <= 8  ? "summer"
                        : month >= 9 && month <= 11 ? "autumn"
                                                    : "winter";
    return {{"dateTime", date.toString(Qt::ISODate)},
            {"timeText", date.time().toString("HH:mm")},
            {"hours", date.time().toString("HH")},
            {"minutes", date.time().toString("mm")},
            {"phase", phase},
            {"season", season},
            {"night", phase == "starry-night" || phase == "moonlit-night"},
            {"weatherAvailable", m_state->value("weather.available")},
            {"weatherMood", weather},
            {"sunVisible", sunVisible},
            {"moonVisible", moonVisible},
            {"sunX", 0.18 + 0.16 * dayProgress},
            {"sunY", phase == "sunset" ? 0.64 : 0.34},
            {"moonX", 0.25},
            {"moonY", 0.34},
            {"astronomy", QVariantMap{{"available", true},
                                      {"simulated", true},
                                      {"sunrise", sunrise.toString("HH:mm")},
                                      {"sunset", sunset.toString("HH:mm")},
                                      {"moonrise", moonrise.toString("HH:mm")},
                                      {"moonset", moonset.toString("HH:mm")},
                                      {"moonPhase", "waning-crescent"}}},
            {"mock", true}};
}
MockTelemetryBackend::MockTelemetryBackend(SystemStateModel *state) : m_state(state) {
    connect(state, &SystemStateModel::changed, this, &TelemetryBackend::changed);
}
QVariantList MockTelemetryBackend::cells() const {
    QVariantList result;
    const auto add = [&](const QString &id, const QString &path, const QString &suffix,
                         bool available) {
        result.append(
            QVariantMap{{"id", id},
                        {"available", available},
                        {"value", available ? QString::number(m_state->value(path).toInt()) + suffix
                                            : QStringLiteral("—")},
                        {"severity", m_state->alerts().value(id, 0)}});
    };
    add("cpu", "cpu.usage", "%", true);
    add("memory", "memory.usedPercent", "%", true);
    add("temperature", "cpu.temperature", "°", m_state->value("capabilities.sensors").toBool());
    add("battery", "battery.percent", m_state->value("battery.charging").toBool() ? "% ↗" : "%",
        m_state->value("capabilities.battery").toBool());
    return result;
}
MockWallpaperEffectsBackend::MockWallpaperEffectsBackend(SystemStateModel *state) : m_state(state) {
    connect(state, &SystemStateModel::changed, this, &WallpaperEffectsBackend::changed);
}
QVariantMap MockWallpaperEffectsBackend::state() const {
    auto result = m_state->value("wallpaperEffects").toMap();
    const auto wallpaper = m_state->value("appearance.wallpaper").toString();
    const bool matching = result.value("cachedWallpaper").toString() == wallpaper;
    const bool ready = result.value("cacheState") == "ready" && matching && wallpaper == "snow";
    const bool saver =
        m_state->value("powerScene") == "power-saver" || result.value("quality") == "power-saver";
    auto mode = result.value("mode").toString();
    if (!ready || saver || !result.value("foreground").toBool()) {
        if (mode == "depth")
            mode = "normal";
    }
    if (!ready || (mode == "soft-blur" && result.value("blurStrength").toInt() == 0))
        mode = "normal";
    result.insert("effectiveMode", mode);
    result.insert("cacheValid", ready);
    result.insert("stale", !matching && result.value("cacheState") == "ready");
    result.insert("mock", true);
    result.insert("depthTier",
                  mode == "depth" ? (result.value("quality") == "refined" ? 3 : 2) : 0);
    // Original pre-authored resource studies, not outputs of a segmentation model.
    result.insert("foregroundAsset", ready && wallpaper == "snow"
                                         ? "qrc:/assets/wallpapers/depth-foreground.svg"
                                         : "");
    result.insert("softAsset", ready ? "qrc:/assets/wallpapers/soft-cache-study.svg" : "");
    result.insert("lockAsset", ready && result.value("lockLinked").toBool() &&
                                       result.value("lockBlurStrength").toInt() > 0
                                   ? "qrc:/assets/wallpapers/lock-cache-study.svg"
                                   : "");
    return result;
}
bool MockWallpaperEffectsBackend::regeneratePreview() {
    // Preview only: never starts a process, writes a cache or downloads a model.
    const auto wallpaper = m_state->value("appearance.wallpaper").toString();
    if (wallpaper != "snow") {
        m_state->requestValue("wallpaperEffects.cacheState", QStringLiteral("failed"));
        return false;
    }
    m_state->requestValue("wallpaperEffects.cachedWallpaper", wallpaper);
    return m_state->requestValue("wallpaperEffects.cacheState", QStringLiteral("ready"));
}
void MockWallpaperEffectsBackend::clearPreview() {
    m_state->requestValue("wallpaperEffects.cacheState", QStringLiteral("empty"));
}
MockWaydroidBackend::MockWaydroidBackend(SystemStateModel *state) : m_state(state) {
    connect(state, &SystemStateModel::changed, this, &WaydroidBackend::changed);
}
QVariantMap MockWaydroidBackend::state() const {
    auto result = m_state->value("waydroid").toMap();
    result.insert("mock", true);
    return result;
}
bool MockWaydroidBackend::setRunning(bool running) {
    return m_state->value("waydroid.available").toBool() &&
           m_state->requestValue("waydroid.running", running);
}
} // namespace klde
