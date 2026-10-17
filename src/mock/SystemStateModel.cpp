// SPDX-License-Identifier: GPL-3.0-or-later
#include "SystemStateModel.h"
#include <QDateTime>
#include <QFile>
#include <QJsonDocument>
#include <QResource>
#include <cmath>

static void initializeMockData() { Q_INIT_RESOURCE(klde_mock_data); }
static void releaseMockData() { Q_CLEANUP_RESOURCE(klde_mock_data); }
namespace {
QVariantMap catalog() {
    QFile file(QStringLiteral(":/src/mock/scenarios.json"));
    return file.open(QIODevice::ReadOnly)
               ? QJsonDocument::fromJson(file.readAll()).toVariant().toMap()
               : QVariantMap{};
}
} // namespace
namespace klde {
SystemStateModel::SystemStateModel(QObject *parent) : QObject(parent) {
    initializeMockData();
    m_baseline = catalog().value("baseline").toMap();
    m_snapshot = m_baseline;
}
SystemStateModel::~SystemStateModel() { releaseMockData(); }
QVariant SystemStateModel::lookup(const QVariantMap &map, const QString &path) {
    QVariant current = map;
    for (const auto &part : path.split('.'))
        current = current.toMap().value(part);
    return current;
}
void SystemStateModel::assign(QVariantMap &map, const QString &path, const QVariant &value) {
    const auto dot = path.indexOf('.');
    if (dot < 0) {
        map.insert(path, value);
        return;
    }
    const auto key = path.left(dot);
    auto child = map.value(key).toMap();
    assign(child, path.mid(dot + 1), value);
    map.insert(key, child);
}
QVariant SystemStateModel::value(const QString &path) const { return lookup(m_snapshot, path); }
bool SystemStateModel::valid(const QString &path, const QVariant &value) const {
    const auto original = lookup(m_baseline, path);
    if (!original.isValid())
        return false;
    const QMap<QString, QStringList> choices{
        {"locale", {"zh_CN", "en"}},
        {"voice", {"standard", "cute"}},
        {"powerScene", {"performance", "balanced", "power-saver"}},
        {"input.currentId", {"pinyin", "keyboard-us"}},
        {"weather.condition",
         {"clear", "partly-cloudy", "cloudy", "rain", "thunderstorm", "snow", "fog", "extreme-heat",
          "extreme-cold"}},
        {"appearance.wallpaper", {"snow", "abstract", "quiet", "kemono"}},
        {"activeApp", {"desktop", "files", "web", "terminal", "notes", "music", "settings"}},
        {"policy.cpu", {"performance", "balanced", "efficient"}},
        {"policy.gpu", {"integrated", "hybrid", "discrete"}},
        {"policy.brightness", {"manual", "adaptive", "dim"}},
        {"audio.output", {"speakers", "headphones", "bluetooth"}}};
    if (choices.contains(path))
        return value.metaType().id() == QMetaType::QString &&
               choices.value(path).contains(value.toString());
    if (path == "time")
        return value.metaType().id() == QMetaType::QString &&
               QDateTime::fromString(value.toString(), Qt::ISODate).isValid();
    if (path == "workspaces.layouts") {
        if (value.metaType().id() != QMetaType::QVariantList || value.toList().size() != 5)
            return false;
        for (const auto &layout : value.toList())
            if (layout.toInt() < 0 || layout.toInt() > 3 || layout.toDouble() != layout.toInt())
                return false;
        return true;
    }
    if (original.metaType().id() == QMetaType::Bool)
        return value.metaType().id() == QMetaType::Bool;
    if (original.canConvert<double>() && original.metaType().id() != QMetaType::QString) {
        const bool numeric = value.metaType().id() == QMetaType::Int ||
                             value.metaType().id() == QMetaType::Double ||
                             value.metaType().id() == QMetaType::LongLong;
        const double number = value.toDouble();
        const int maximum = path == "cpu.temperature" || path == "gpu.temperature" ? 120
                            : path == "policy.refreshRate"                         ? 240
                            : path == "notifications.count"                        ? 12
                            : path == "workspaces.active"                          ? 5
                                                                                   : 100;
        const int minimum = path == "weather.temperature" ? -60
                            : path == "workspaces.active" ? 1
                                                          : 0;
        return numeric && std::isfinite(number) && std::floor(number) == number &&
               number >= minimum && number <= maximum;
    }
    return value.metaType().id() == QMetaType::QString && value.toString().size() <= 128;
}
bool SystemStateModel::requestValue(const QString &path, const QVariant &newValue) {
    if (!valid(path, newValue))
        return false;
    const QMap<QString, QString> needs{
        {"battery.percent", "battery"},       {"cpu.temperature", "sensors"},
        {"audio.microphone", "microphone"},   {"bluetooth.enabled", "bluetooth"},
        {"brightness", "brightness"},         {"policy.frequency", "cpuPolicy"},
        {"policy.refreshRate", "refreshRate"}};
    if (needs.contains(path) && !value("capabilities." + needs.value(path)).toBool())
        return false;
    if (path == "policy.gpu" && newValue != "integrated" &&
        !value("capabilities.discreteGpu").toBool())
        return false;
    if (value(path) == newValue)
        return true;
    assign(m_snapshot, path, newValue);
    emit changed();
    emit valueEdited(path);
    return true;
}
bool SystemStateModel::replacePreview(const QVariantMap &snapshot) {
    // Scenario files are trusted resources; validate every leaf before publication.
    const auto visit = [this](const auto &self, const QVariantMap &map,
                              const QString &prefix) -> bool {
        for (auto it = map.cbegin(); it != map.cend(); ++it) {
            const auto path = prefix.isEmpty() ? it.key() : prefix + '.' + it.key();
            if (it.value().metaType().id() == QMetaType::QVariantMap) {
                if (it.value().toMap().keys() != lookup(m_baseline, path).toMap().keys() ||
                    !self(self, it.value().toMap(), path))
                    return false;
            } else if (!valid(path, it.value()))
                return false;
        }
        return true;
    };
    if (snapshot.keys() != m_baseline.keys() || !visit(visit, snapshot, {}))
        return false;
    m_snapshot = snapshot;
    emit changed();
    return true;
}
bool SystemStateModel::advanceMinutes(int minutes) {
    if (minutes < 1 || minutes > 60)
        return false;
    return requestValue(QStringLiteral("time"),
                        QDateTime::fromString(value("time").toString(), Qt::ISODate)
                            .addSecs(qint64{60} * minutes)
                            .toString(Qt::ISODate));
}
MockScenarioManager::MockScenarioManager(SystemStateModel *state, QObject *parent)
    : QObject(parent), m_state(state), m_scenarios(catalog().value("scenarios").toList()) {
    apply(QStringLiteral("laptop-balanced"));
}
bool MockScenarioManager::apply(const QString &id) {
    for (const auto &entry : m_scenarios) {
        const auto scenario = entry.toMap();
        if (scenario.value("id").toString() != id)
            continue;
        auto next = m_state->baseline();
        const auto overrides = scenario.value("overrides").toMap();
        for (auto it = overrides.cbegin(); it != overrides.cend(); ++it) {
            if (!m_state->valid(it.key(), it.value()))
                return false;
            SystemStateModel::assign(next, it.key(), it.value());
        }
        if (!m_state->replacePreview(next))
            return false;
        m_active = id;
        emit applied();
        return true;
    }
    return false;
}
} // namespace klde
