// SPDX-License-Identifier: GPL-3.0-or-later
#include "PowerSceneController.h"

namespace klde {
QVariantList PowerSceneController::defaults() {
    const auto scene = [](const QString &id, const QString &name, const QString &icon,
                          const QString &description, const QString &profile, int quality,
                          int motion, bool shadows) {
        return QVariantMap{{"id", id},
                           {"name", name},
                           {"icon", icon},
                           {"description", description},
                           {"profile", profile},
                           {"customized", false},
                           {"visual", QVariantMap{{"theme", "auto"},
                                                  {"blurEnabled", true},
                                                  {"blurQuality", quality},
                                                  {"transparency", true},
                                                  {"shadows", shadows},
                                                  {"motion", motion},
                                                  {"density", 1},
                                                  {"shadowLevel", motion == 2 ? 1 : 0}}}};
    };
    return {scene("performance", tr("Performance"), "sun", tr("Room for demanding work"),
                  "Performance", BlurBackend::Low, 3, true),
            scene("balanced", tr("Balanced"), "leaf", tr("A comfortable everyday rhythm"),
                  "Balanced", BlurBackend::Medium, 2, true),
            scene("power-saver", tr("Power Saver"), "moon", tr("Stay light, keep the softness"),
                  "Power saver", BlurBackend::Low, 0, true)};
}
PowerSceneController::PowerSceneController(SystemBackend *system, BlurBackend *blur,
                                           QObject *parent)
    : QObject(parent), m_system(system), m_blur(blur), m_scenes(defaults()) {
    Q_ASSERT(system != nullptr && blur != nullptr);
    apply();
}
QString PowerSceneController::activeId() const { return current().value("id").toString(); }
QVariantMap PowerSceneController::current() const { return m_scenes.at(m_active).toMap(); }
QVariantMap PowerSceneController::capabilities() const {
    return {{"systemProfile", true}, {"visualPolicy", true},     {"cpuFrequency", false},
            {"gpuPolicy", false},    {"discreteGpu", false},     {"refreshRate", false},
            {"systemIsMock", true},  {"persistentScenes", false}};
}
bool PowerSceneController::select(const QString &id) {
    for (qsizetype i = 0; i < m_scenes.size(); ++i) {
        if (m_scenes.at(i).toMap().value("id").toString() == id) {
            if (m_active != i) {
                m_active = i;
                apply();
                emit currentChanged();
            }
            return true;
        }
    }
    emit requestRejected(tr("That power scene is unavailable"));
    return false;
}
bool PowerSceneController::customize(const QString &option, const QVariant &value) {
    bool valid = false;
    if (option == "theme") {
        valid = value.metaType().id() == QMetaType::QString &&
                QStringList{"auto", "light", "dark"}.contains(value.toString());
    } else if (option == "blurEnabled" || option == "transparency" || option == "shadows") {
        valid = value.metaType().id() == QMetaType::Bool;
    } else if (option == "blurQuality" || option == "motion" || option == "density" ||
               option == "shadowLevel") {
        bool converted = false;
        const int number = value.toInt(&converted);
        const bool numeric =
            value.metaType().id() == QMetaType::Int || value.metaType().id() == QMetaType::Double;
        valid = numeric && converted && value.toDouble() == number &&
                (option == "blurQuality" ? number >= BlurBackend::Low && number <= BlurBackend::High
                                         : number >= 0 && number <= (option == "motion" ? 3 : 2));
    }
    if (!valid) {
        emit requestRejected(tr("That scene option is invalid or unsupported"));
        return false;
    }
    auto scene = current();
    auto visual = scene.value("visual").toMap();
    if (visual.value(option) == value) {
        return true;
    }
    visual.insert(option, value);
    scene.insert("visual", visual);
    scene.insert("customized", visual != defaults().at(m_active).toMap().value("visual").toMap());
    m_scenes[m_active] = scene;
    apply();
    emit scenesChanged();
    emit currentChanged();
    return true;
}
void PowerSceneController::resetDefaults() {
    m_scenes = defaults();
    m_active = 1;
    apply();
    emit scenesChanged();
    emit currentChanged();
}
void PowerSceneController::resetCurrent() {
    m_scenes[m_active] = defaults().at(m_active);
    apply();
    emit scenesChanged();
    emit currentChanged();
}
void PowerSceneController::apply() {
    const auto scene = current();
    const auto visual = scene.value("visual").toMap();
    m_system->setPowerProfile(scene.value("profile").toString());
    m_blur->setQuality(visual.value("blurEnabled").toBool()
                           ? static_cast<BlurBackend::Quality>(visual.value("blurQuality").toInt())
                           : BlurBackend::Off);
}
} // namespace klde
