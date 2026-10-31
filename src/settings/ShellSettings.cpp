// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellSettings.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QSettings>

namespace klde {

ShellSettings::ShellSettings(QObject *parent) : QObject(parent) {
    const auto string = QMetaType::fromType<QString>();
    const auto boolean = QMetaType::fromType<bool>();
    const auto integer = QMetaType::fromType<int>();
    define(QStringLiteral("appearance.accent"), string, QStringLiteral("auto"),
           {QStringLiteral("auto"), QStringLiteral("teal"), QStringLiteral("lilac"),
            QStringLiteral("apricot")});
    define(QStringLiteral("appearance.wallpaper"), string, QStringLiteral("snow"),
           {QStringLiteral("snow"), QStringLiteral("abstract"), QStringLiteral("quiet"),
            QStringLiteral("kemono")});
    // Empty locale means "keep the session's language".
    define(QStringLiteral("language.locale"), string, QString(),
           {QString(), QStringLiteral("en"), QStringLiteral("zh_CN")});
    define(QStringLiteral("language.voice"), string, QStringLiteral("standard"),
           {QStringLiteral("standard"), QStringLiteral("cute")});
    // smart: hide while a window overlaps; reserve: keep an exclusive zone.
    define(QStringLiteral("dock.mode"), string, QStringLiteral("smart"),
           {QStringLiteral("smart"), QStringLiteral("reserve"), QStringLiteral("hidden")});
    define(QStringLiteral("ribbon.enabled"), boolean, true);
    define(QStringLiteral("ribbon.compact"), boolean, false);
    define(QStringLiteral("ribbon.margin"), integer, 16, {}, 4, 40);
    define(QStringLiteral("ribbon.spacing"), integer, 6, {}, 2, 16);
    // Power scenes own their defaults; stored values are explicit overrides.
    for (const auto *scene : {"performance", "balanced", "power-saver"}) {
        const auto prefix = QStringLiteral("scenes.%1.").arg(QLatin1StringView(scene));
        define(prefix + QStringLiteral("theme"), string, {},
               {QStringLiteral("auto"), QStringLiteral("light"), QStringLiteral("dark")});
        define(prefix + QStringLiteral("transparency"), boolean);
        define(prefix + QStringLiteral("shadows"), boolean);
        define(prefix + QStringLiteral("blurEnabled"), boolean);
        define(prefix + QStringLiteral("blurQuality"), integer, {}, {}, 1, 3);
        define(prefix + QStringLiteral("motion"), integer, {}, {}, 0, 3);
        define(prefix + QStringLiteral("density"), integer, {}, {}, 0, 2);
    }
}

void ShellSettings::define(const QString &key, QMetaType type, const QVariant &defaultValue,
                           const QStringList &choices, int minimum, int maximum) {
    m_schema.insert(key, {defaultValue, type, choices, minimum, maximum});
    if (defaultValue.isValid())
        m_values.insert(key, defaultValue);
    else
        m_values.remove(key);
    if (!m_path.isEmpty()) {
        QSettings file(m_path, QSettings::IniFormat);
        load(file, key);
    }
}

QString ShellSettings::storageKey(const QString &key) {
    return QString(key).replace(QLatin1Char('.'), QLatin1Char('/'));
}

QVariant ShellSettings::normalized(const QString &key, const QVariant &value,
                                   bool fromStorage) const {
    const auto entry = m_schema.constFind(key);
    if (entry == m_schema.constEnd() || !value.isValid())
        return {};
    const auto id = value.metaType().id();
    if (entry->type == QMetaType::fromType<bool>()) {
        if (id == QMetaType::Bool)
            return value;
        if (fromStorage && id == QMetaType::QString &&
            (value.toString() == QStringLiteral("true") ||
             value.toString() == QStringLiteral("false")))
            return value.toString() == QStringLiteral("true");
        return {};
    }
    if (entry->type == QMetaType::fromType<int>()) {
        bool converted = false;
        int number = 0;
        if (id == QMetaType::Int || id == QMetaType::LongLong) {
            number = value.toInt(&converted);
        } else if (id == QMetaType::Double) {
            number = value.toInt(&converted);
            converted = converted && value.toDouble() == number;
        } else if (fromStorage && id == QMetaType::QString) {
            number = value.toString().toInt(&converted);
        }
        if (!converted || (entry->minimum < entry->maximum &&
                           (number < entry->minimum || number > entry->maximum)))
            return {};
        return number;
    }
    if (id != QMetaType::QString)
        return {};
    const auto text = value.toString();
    if (!entry->choices.isEmpty() && !entry->choices.contains(text))
        return {};
    return text.left(256);
}

QVariant ShellSettings::value(const QString &key) const { return m_values.value(key); }

bool ShellSettings::setValue(const QString &key, const QVariant &value) {
    const auto next = normalized(key, value, false);
    if (!next.isValid())
        return false;
    if (m_values.value(key) == next)
        return true;
    m_values.insert(key, next);
    store(key);
    emit valueChanged(key);
    emit changed();
    return true;
}

void ShellSettings::reset(const QString &key) {
    const auto entry = m_schema.constFind(key);
    if (entry == m_schema.constEnd())
        return;
    if (m_values.value(key) == entry->defaultValue)
        return;
    if (entry->defaultValue.isValid())
        m_values.insert(key, entry->defaultValue);
    else
        m_values.remove(key);
    store(key);
    emit valueChanged(key);
    emit changed();
}

void ShellSettings::migrate(QSettings &file, int from) {
    // Version 0 is a missing or unversioned file. Version 1 is the first
    // schema, so there is nothing to rename; invalid values are dropped by
    // load(). Later schema changes add one step per version here, e.g.
    //   if (from < 2) { rename "dock/autohide" to "dock/mode"; }
    Q_UNUSED(from)
    file.setValue(QStringLiteral("meta/version"), CurrentVersion);
}

void ShellSettings::load(QSettings &file, const QString &key) {
    const auto stored = storageKey(key);
    if (!file.contains(stored))
        return;
    const auto next = normalized(key, file.value(stored), true);
    if (next.isValid())
        m_values.insert(key, next);
    else if (!m_readOnly)
        file.remove(stored);
}

bool ShellSettings::enablePersistence(const QString &directory) {
    if (!m_path.isEmpty() || directory.isEmpty() || !QDir().mkpath(directory))
        return false;
    const auto path = QDir(directory).filePath(QStringLiteral("shell.conf"));
    {
        QSettings probe(path, QSettings::IniFormat);
        if (probe.status() == QSettings::FormatError) {
            // Keep the unreadable file for the user instead of overwriting it.
            const auto backup =
                path + QStringLiteral(".broken-") +
                QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyyMMddHHmmss"));
            if (!QFile::rename(path, backup))
                return false;
        }
    }
    QSettings file(path, QSettings::IniFormat);
    if (file.status() != QSettings::NoError)
        return false;
    const int version = file.value(QStringLiteral("meta/version"), 0).toInt();
    m_readOnly = version > CurrentVersion;
    if (version < CurrentVersion)
        migrate(file, version);
    m_path = path;
    for (auto key = m_schema.cbegin(); key != m_schema.cend(); ++key)
        load(file, key.key());
    if (!m_readOnly)
        file.sync();
    emit persistenceChanged();
    emit changed();
    return file.status() == QSettings::NoError;
}

void ShellSettings::store(const QString &key) const {
    if (!persistent())
        return;
    QSettings file(m_path, QSettings::IniFormat);
    if (m_values.contains(key))
        file.setValue(storageKey(key), m_values.value(key));
    else
        file.remove(storageKey(key));
    file.setValue(QStringLiteral("meta/version"), CurrentVersion);
    file.sync();
}

} // namespace klde
