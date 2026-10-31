// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QHash>
#include <QMetaType>
#include <QObject>
#include <QStringList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class QSettings;

namespace klde {

// Typed, versioned owoDE preferences. Every session keeps the values in memory;
// only system/native sessions enable the on-disk store below ~/.config/owode.
// The Visual Lab therefore always starts from the same schema defaults.
class ShellSettings : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.settings")
    Q_PROPERTY(QVariantMap values READ values NOTIFY changed)
    Q_PROPERTY(bool persistent READ persistent NOTIFY persistenceChanged)
    Q_PROPERTY(bool readOnly READ readOnly NOTIFY persistenceChanged)
    Q_PROPERTY(QString path READ path NOTIFY persistenceChanged)
    Q_PROPERTY(int version READ version CONSTANT)

  public:
    static constexpr int CurrentVersion = 1;

    explicit ShellSettings(QObject *parent = nullptr);

    QVariantMap values() const { return m_values; }
    // True when changes are written to disk.
    bool persistent() const { return !m_path.isEmpty() && !m_readOnly; }
    // A file written by a newer owoDE is loaded but never overwritten.
    bool readOnly() const { return m_readOnly; }
    QString path() const { return m_path; }
    int version() const { return CurrentVersion; }

    // Loads, validates and migrates <directory>/shell.conf, then keeps it in
    // sync. Returns false when the file cannot be used; values stay in memory.
    bool enablePersistence(const QString &directory);

    Q_INVOKABLE QVariant value(const QString &key) const;
    // Rejects unknown keys and values outside the key's type or range.
    Q_INVOKABLE bool setValue(const QString &key, const QVariant &value);
    Q_INVOKABLE void reset(const QString &key);
    Q_INVOKABLE bool contains(const QString &key) const { return m_schema.contains(key); }
    QStringList keys() const { return m_schema.keys(); }
    // Registers a key. An invalid default means "unset": value() returns an
    // invalid QVariant until something is stored, e.g. per-scene overrides.
    // Keys defined after enablePersistence() are loaded from disk on definition.
    void define(const QString &key, QMetaType type, const QVariant &defaultValue = {},
                const QStringList &choices = {}, int minimum = 0, int maximum = 0);

  signals:
    void changed();
    void valueChanged(const QString &key);
    void persistenceChanged();

  private:
    struct Entry {
        QVariant defaultValue;
        QMetaType type;
        QStringList choices;
        int minimum = 0;
        int maximum = 0;
    };
    QVariant normalized(const QString &key, const QVariant &value, bool fromStorage) const;
    static QString storageKey(const QString &key);
    static void migrate(QSettings &file, int from);
    void load(QSettings &file, const QString &key);
    void store(const QString &key) const;

    QHash<QString, Entry> m_schema;
    QVariantMap m_values;
    QString m_path;
    bool m_readOnly = false;
};

} // namespace klde
