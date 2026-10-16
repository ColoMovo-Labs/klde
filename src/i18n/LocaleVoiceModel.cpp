// SPDX-License-Identifier: GPL-3.0-or-later
#include "LocaleVoiceModel.h"
#include <QDate>
#include <QFile>
#include <QJsonDocument>
#include <QLocale>
#include <QResource>
#include <algorithm>

// Resource initialization stays outside a C++ namespace, as required by Qt.
static void initializeCatalogs() { Q_INIT_RESOURCE(klde_translations); }
static void releaseCatalogs() { Q_CLEANUP_RESOURCE(klde_translations); }

namespace {
QJsonObject readCatalog(const QString &path) {
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? QJsonDocument::fromJson(file.readAll()).object()
                                          : QJsonObject{};
}
} // namespace
namespace klde {
LocaleVoiceModel::LocaleVoiceModel(QObject *parent) : QObject(parent) {
    initializeCatalogs();
    m_locale = QLocale::system().language() == QLocale::Chinese ? "zh_CN" : "en";
    m_english = readCatalog(QStringLiteral(":/translations/en.json"));
    m_chinese = readCatalog(QStringLiteral(":/translations/zh_CN.json"));
    m_cuteEnglish = readCatalog(QStringLiteral(":/translations/voices/cute/en.json"));
    m_cuteChinese = readCatalog(QStringLiteral(":/translations/voices/cute/zh_CN.json"));
    for (auto it = m_english.constBegin(); it != m_english.constEnd(); ++it)
        m_sourceIds.insert(it.value().toString(), it.key());
}
LocaleVoiceModel::~LocaleVoiceModel() { releaseCatalogs(); }
bool LocaleVoiceModel::setLocale(const QString &locale) {
    if (locale != "en" && locale != "zh_CN")
        return false;
    if (m_locale != locale) {
        m_locale = locale;
        ++m_revision;
        emit changed();
    }
    return true;
}
bool LocaleVoiceModel::setVoice(const QString &voice) {
    if (voice != "standard" && voice != "cute")
        return false;
    if (m_voice != voice) {
        m_voice = voice;
        ++m_revision;
        emit changed();
    }
    return true;
}
bool LocaleVoiceModel::toneOverrideAllowed(const QString &id) {
    return id.startsWith("shell.") || id.startsWith("friendly.") || id.startsWith("ambient.");
}
QString LocaleVoiceModel::text(const QString &id, int revision) const {
    Q_UNUSED(revision)
    const auto &base = m_locale == "zh_CN" ? m_chinese : m_english;
    const auto &cute = m_locale == "zh_CN" ? m_cuteChinese : m_cuteEnglish;
    if (m_voice == "cute" && toneOverrideAllowed(id) && cute.contains(id))
        return cute.value(id).toString();
    if (base.contains(id))
        return base.value(id).toString();
    return m_english.contains(id) ? m_english.value(id).toString() : "[" + id + "]";
}
QString LocaleVoiceModel::sourceText(const QString &source, int revision) const {
    Q_UNUSED(revision)
    return resolveSource(source, 0);
}
QString LocaleVoiceModel::resolveSource(const QString &source, int depth) const {
    const auto exact = m_sourceIds.constFind(source);
    if (exact != m_sourceIds.constEnd())
        return text(exact.value());
    // Only the existing owned one-argument notices need this temporary bridge.
    if (depth < 2 && source.size() <= 4096) {
        for (auto it = m_sourceIds.constBegin(); it != m_sourceIds.constEnd(); ++it) {
            const auto position = it.key().indexOf("%1");
            if (position < 0 || it.key().contains("%2"))
                continue;
            const QString prefix = it.key().left(position);
            const QString suffix = it.key().mid(position + 2);
            if (source.size() >= prefix.size() + suffix.size() && source.startsWith(prefix) &&
                source.endsWith(suffix)) {
                const QString argument =
                    source.mid(prefix.size(), source.size() - prefix.size() - suffix.size());
                return text(it.value()).arg(resolveSource(argument, depth + 1));
            }
        }
    }
    return source;
}
QString LocaleVoiceModel::number(double value, int precision) const {
    return QLocale(m_locale).toString(value, 'f', std::clamp(precision, 0, 3));
}
QString LocaleVoiceModel::previewClock(int revision) const {
    Q_UNUSED(revision)
    return QLocale(m_locale).toString(QDate(2026, 10, 16), m_locale == "zh_CN"
                                                               ? QStringLiteral("M月d日 ddd")
                                                               : QStringLiteral("ddd, d MMM")) +
           QStringLiteral(" 09:41");
}
} // namespace klde
