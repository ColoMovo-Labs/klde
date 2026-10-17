// SPDX-License-Identifier: GPL-3.0-or-later
#include "StatusModuleRegistry.h"
#include <QFile>
#include <QJsonDocument>
#include <QResource>
#include <algorithm>
static void initializeModules() { Q_INIT_RESOURCE(klde_mock_data); }
static void releaseModules() { Q_CLEANUP_RESOURCE(klde_mock_data); }
namespace klde {
StatusModuleRegistry::StatusModuleRegistry(QObject *parent) : QObject(parent) {
    initializeModules();
    reset();
}
StatusModuleRegistry::~StatusModuleRegistry() { releaseModules(); }
void StatusModuleRegistry::reset() {
    QFile file(QStringLiteral(":/src/status/modules.json"));
    if (file.open(QIODevice::ReadOnly))
        m_modules = QJsonDocument::fromJson(file.readAll()).toVariant().toList();
    m_enabled = true;
    m_compact = false;
    m_margin = 16;
    m_spacing = 6;
    emit changed();
}
void StatusModuleRegistry::setEnabled(bool enabled) {
    if (m_enabled != enabled) {
        m_enabled = enabled;
        emit changed();
    }
}
void StatusModuleRegistry::setCompact(bool compact) {
    if (m_compact != compact) {
        m_compact = compact;
        emit changed();
    }
}
void StatusModuleRegistry::setMargin(int margin) {
    margin = std::clamp(margin, 4, 40);
    if (m_margin != margin) {
        m_margin = margin;
        emit changed();
    }
}
void StatusModuleRegistry::setSpacing(int spacing) {
    spacing = std::clamp(spacing, 2, 16);
    if (m_spacing != spacing) {
        m_spacing = spacing;
        emit changed();
    }
}
bool StatusModuleRegistry::setVisible(const QString &id, bool visible) {
    for (auto &item : m_modules) {
        auto entry = item.toMap();
        if (entry.value("id").toString() == id) {
            entry["enabled"] = visible;
            item = entry;
            emit changed();
            return true;
        }
    }
    return false;
}
bool StatusModuleRegistry::setSection(const QString &id, int section) {
    if (section < 0 || section > 2)
        return false;
    for (auto &item : m_modules) {
        auto entry = item.toMap();
        if (entry.value("id").toString() == id) {
            entry["section"] = section;
            item = entry;
            emit changed();
            return true;
        }
    }
    return false;
}
bool StatusModuleRegistry::move(const QString &id, int delta) {
    if (delta != -1 && delta != 1)
        return false;
    for (qsizetype i = 0; i < m_modules.size(); ++i)
        if (m_modules.at(i).toMap().value("id").toString() == id) {
            const auto section = m_modules.at(i).toMap().value("section");
            for (qsizetype j = i + delta; j >= 0 && j < m_modules.size(); j += delta)
                if (m_modules.at(j).toMap().value("section") == section) {
                    m_modules.swapItemsAt(i, j);
                    emit changed();
                    return true;
                }
            return false;
        }
    return false;
}
} // namespace klde
