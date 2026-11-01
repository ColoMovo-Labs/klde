// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

namespace klde {

// Opens system-level settings that owoDE does not implement yet in installed
// GNOME Settings panels or KWin configuration modules. Only panels that talk
// to system services (NetworkManager, BlueZ, PipeWire, accountsservice,
// timedated, CUPS ...) are offered; GNOME panels that only work with Mutter or
// gnome-settings-daemon, or that would rewrite the GNOME session's own
// preferences, are left out.
class SystemSettingsBridge : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.systemSettings")
    Q_PROPERTY(QVariantList entries READ entries NOTIFY changed)
    Q_PROPERTY(bool enabled READ enabled NOTIFY changed)

  public:
    explicit SystemSettingsBridge(QObject *parent = nullptr);
    // Explicit discovery roots keep contract tests independent of host apps.
    SystemSettingsBridge(QStringList executablePaths, QStringList pluginPaths,
                         QObject *parent = nullptr);

    // [{id, provider: "gnome"|"kwin", available}], in display order.
    QVariantList entries() const { return m_entries; }
    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool available(const QString &id) const;
    // Starts the panel detached. GNOME Settings refuses to run outside GNOME,
    // so only its own process sees XDG_CURRENT_DESKTOP=GNOME.
    Q_INVOKABLE bool open(const QString &id);

  signals:
    void changed();
    void opened(const QString &id);
    void failed(const QString &id);

  private:
    QString findExecutable(const QString &name) const;
    bool kcmInstalled(const QString &module) const;
    QStringList m_executablePaths;
    QStringList m_pluginPaths;
    QString m_gnome;
    QString m_kcmshell;
    QVariantList m_entries;
    bool m_enabled = false;
};

} // namespace klde
