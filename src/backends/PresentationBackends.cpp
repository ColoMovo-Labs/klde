// SPDX-License-Identifier: GPL-3.0-or-later
#include "PresentationBackends.h"
#include <QDateTime>

namespace klde {
MockTimeBackend::MockTimeBackend(SystemStateModel *state) : m_state(state) {
    connect(state, &SystemStateModel::changed, this, &TimeBackend::changed);
}
QVariantMap MockTimeBackend::reading() const {
    const auto date = QDateTime::fromString(m_state->value("time").toString(), Qt::ISODate);
    const auto hour = date.time().hour();
    auto phase = m_state->value("temporal.phase").toString();
    const auto weather = m_state->value("weather.condition").toString();
    if (phase == "auto") {
        if (hour < 6 || hour >= 19)
            phase = weather == "clear" ? "starry-night" : "moonlit-night";
        else if (hour < 11)
            phase = "clear-morning";
        else if (hour < 17)
            phase = "cloudy-day";
        else
            phase = weather == "rain" || weather == "thunderstorm" ? "rainy-evening" : "sunset";
    }
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
