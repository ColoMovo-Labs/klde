// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QJsonObject>
#include <QMap>
#include <QObject>
#include <QtQml/qqmlregistration.h>

namespace klde {
class LocaleVoiceModel : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Shell.language")
    Q_PROPERTY(QString locale READ locale NOTIFY changed)
    Q_PROPERTY(QString voice READ voice NOTIFY changed)
    Q_PROPERTY(int revision READ revision NOTIFY changed)
    Q_PROPERTY(bool ready READ ready CONSTANT)
  public:
    explicit LocaleVoiceModel(QObject *parent = nullptr);
    ~LocaleVoiceModel() override;
    QString locale() const { return m_locale; }
    QString voice() const { return m_voice; }
    int revision() const { return m_revision; }
    bool ready() const { return !m_english.isEmpty() && !m_chinese.isEmpty(); }
    Q_INVOKABLE bool setLocale(const QString &locale);
    Q_INVOKABLE bool setVoice(const QString &voice);
    Q_INVOKABLE QString text(const QString &id, int revision = 0) const;
    // Migration bridge for KLDE-owned mock strings, never external application metadata.
    Q_INVOKABLE QString sourceText(const QString &source, int revision = 0) const;
    Q_INVOKABLE QString number(double value, int precision = 0) const;
    Q_INVOKABLE QString previewClock(int revision = 0) const;
    static bool toneOverrideAllowed(const QString &id);
  signals:
    void changed();

  private:
    QString resolveSource(const QString &source, int depth) const;
    QString m_locale;
    QString m_voice = QStringLiteral("standard");
    QJsonObject m_english;
    QJsonObject m_chinese;
    QJsonObject m_cuteEnglish;
    QJsonObject m_cuteChinese;
    QMap<QString, QString> m_sourceIds;
    int m_revision = 0;
};
} // namespace klde
