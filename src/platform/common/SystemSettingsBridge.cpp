// SPDX-License-Identifier: GPL-3.0-or-later
#include "SystemSettingsBridge.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QLibraryInfo>
#include <QProcess>
#include <QProcessEnvironment>
#include <utility>

namespace klde {

namespace {
// GNOME Settings panels that work under KWin because they talk to system
// services directly. Omitted on purpose: display, power, keyboard, mouse,
// background, multitasking, notifications, universal-access (they need
// Mutter or gnome-settings-daemon, or write GNOME-only preferences).
constexpr const char *GnomePanels[] = {"wifi",     "network",         "bluetooth",    "sound",
                                       "printers", "online-accounts", "applications", "system"};
// KWin's own configuration modules; kcm_kscreen comes from the kscreen package.
constexpr const char *KWinModules[] = {
    "kcm_kscreen",   "kcm_kwinoptions", "kcm_kwin_virtualdesktops",
    "kcm_kwinrules", "kcm_kwintabbox",  "kcm_kwinscreenedges"};

QStringList pluginPaths() {
    auto paths = QCoreApplication::libraryPaths();
    paths.append(QLibraryInfo::path(QLibraryInfo::PluginsPath));
    paths.removeDuplicates();
    return paths;
}
} // namespace

SystemSettingsBridge::SystemSettingsBridge(QObject *parent)
    : SystemSettingsBridge(
          qEnvironmentVariable("PATH").split(QDir::listSeparator(), Qt::SkipEmptyParts),
          pluginPaths(), parent) {}

SystemSettingsBridge::SystemSettingsBridge(QStringList executablePaths, QStringList pluginPaths,
                                           QObject *parent)
    : QObject(parent), m_executablePaths(std::move(executablePaths)),
      m_pluginPaths(std::move(pluginPaths)) {
    refresh();
}

QString SystemSettingsBridge::findExecutable(const QString &name) const {
    for (const auto &directory : m_executablePaths) {
        const QFileInfo file(QDir(directory).filePath(name));
        if (file.isFile() && file.isExecutable())
            return file.absoluteFilePath();
    }
    return {};
}

bool SystemSettingsBridge::kcmInstalled(const QString &module) const {
    for (const auto &plugins : m_pluginPaths) {
        for (const auto *directory :
             {"plasma/kcms/systemsettings/", "plasma/kcms/systemsettings_qwidgets/"}) {
            const QFileInfo file(QDir(plugins).filePath(QLatin1StringView(directory) + module +
                                                        QStringLiteral(".so")));
            if (file.isFile())
                return true;
        }
    }
    return false;
}

void SystemSettingsBridge::setEnabled(bool enabled) {
    if (m_enabled == enabled)
        return;
    m_enabled = enabled;
    emit changed();
}

void SystemSettingsBridge::refresh() {
    m_gnome = findExecutable(QStringLiteral("gnome-control-center"));
    m_kcmshell = findExecutable(QStringLiteral("kcmshell6"));
    QVariantList entries;
    for (const auto *panel : GnomePanels) {
        entries.append(QVariantMap{{QStringLiteral("id"), QString::fromLatin1(panel)},
                                   {QStringLiteral("provider"), QStringLiteral("gnome")},
                                   {QStringLiteral("available"), !m_gnome.isEmpty()}});
    }
    for (const auto *module : KWinModules) {
        const auto id = QString::fromLatin1(module);
        entries.append(
            QVariantMap{{QStringLiteral("id"), id},
                        {QStringLiteral("provider"), QStringLiteral("kwin")},
                        {QStringLiteral("available"), !m_kcmshell.isEmpty() && kcmInstalled(id)}});
    }
    if (entries == m_entries)
        return;
    m_entries = entries;
    emit changed();
}

bool SystemSettingsBridge::available(const QString &id) const {
    for (const auto &item : m_entries) {
        const auto entry = item.toMap();
        if (entry.value(QStringLiteral("id")).toString() == id)
            return entry.value(QStringLiteral("available")).toBool();
    }
    return false;
}

bool SystemSettingsBridge::open(const QString &id) {
    // Visual Lab and design previews must never open host system controls.
    if (!m_enabled) {
        emit failed(id);
        return false;
    }
    refresh();
    QString provider;
    for (const auto &item : m_entries) {
        const auto entry = item.toMap();
        if (entry.value(QStringLiteral("id")).toString() == id &&
            entry.value(QStringLiteral("available")).toBool())
            provider = entry.value(QStringLiteral("provider")).toString();
    }
    if (provider.isEmpty()) {
        emit failed(id);
        return false;
    }
    QProcess process;
    if (provider == QStringLiteral("gnome")) {
        auto environment = QProcessEnvironment::systemEnvironment();
        environment.insert(QStringLiteral("XDG_CURRENT_DESKTOP"), QStringLiteral("GNOME"));
        process.setProcessEnvironment(environment);
        process.setProgram(m_gnome);
    } else {
        process.setProgram(m_kcmshell);
    }
    process.setArguments({id});
    if (!process.startDetached()) {
        emit failed(id);
        return false;
    }
    emit opened(id);
    return true;
}

} // namespace klde
