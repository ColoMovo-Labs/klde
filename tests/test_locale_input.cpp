// SPDX-License-Identifier: GPL-3.0-or-later
#include "i18n/LocaleVoiceModel.h"
#include "input/Fcitx5Backend.h"
#include "weather/WeatherProvider.h"
#include <QSignalSpy>
#include <QtTest>

class LocaleInputTest final : public QObject {
    Q_OBJECT
  private slots:
    void localeVoiceFallbackAndCriticalToneAreIndependent() {
        klde::LocaleVoiceModel language;
        QVERIFY(language.ready());
        QVERIFY(language.setLocale(QStringLiteral("zh_CN")));
        QCOMPARE(language.text(QStringLiteral("common.off")), QStringLiteral("关闭"));
        const auto standard = language.text(QStringLiteral("shell.quick.title"));
        const auto privacy = language.text(QStringLiteral("privacy.weather.disclosure"));
        QVERIFY(language.setVoice(QStringLiteral("cute")));
        QVERIFY(language.text(QStringLiteral("shell.quick.title")) != standard);
        QCOMPARE(language.text(QStringLiteral("common.off")), QStringLiteral("关闭"));
        QCOMPARE(language.text(QStringLiteral("privacy.weather.disclosure")), privacy);
        for (const auto *prefix :
             {"security.", "privacy.", "legal.", "destructive.", "critical.", "authentication.",
              "storage.failure.", "certificate.", "permission."})
            QVERIFY(
                !klde::LocaleVoiceModel::toneOverrideAllowed(QString::fromLatin1(prefix) + "test"));
        QVERIFY(!language.setLocale(QStringLiteral("zh_CN_cute")));
        QVERIFY(!language.setVoice(QStringLiteral("unknown")));
        QCOMPARE(language.locale(), QStringLiteral("zh_CN"));
        QCOMPARE(language.text(QStringLiteral("missing.id")), QStringLiteral("[missing.id]"));
        QVERIFY(language.previewClock().contains(QStringLiteral("10月16日")));
        QVERIFY(language.sourceText(QStringLiteral("Preview: Terminal is active"))
                    .contains(QStringLiteral("终端")));
        QVERIFY(language.setLocale(QStringLiteral("en")));
        QCOMPARE(language.text(QStringLiteral("security.authentication.failed")),
                 QStringLiteral("Authentication failed."));
    }
    void modelsDoNotShareUserPreferences() {
        klde::LocaleVoiceModel first;
        klde::LocaleVoiceModel second;
        second.setLocale(QStringLiteral("en"));
        first.setLocale(QStringLiteral("zh_CN"));
        first.setVoice(QStringLiteral("cute"));
        QCOMPARE(second.locale(), QStringLiteral("en"));
        QCOMPARE(second.voice(), QStringLiteral("standard"));
    }
    void detectionNeverClaimsActualInputSwitching() {
        klde::Fcitx5Backend input;
        QVERIFY(input.simulated());
        QVERIFY(!input.switchingSupported());
        QVERIFY(!input.requestSwitch(QStringLiteral("pinyin")));
        QVERIFY(input.selectPreview(QStringLiteral("pinyin")));
        QCOMPARE(input.indicator(), QStringLiteral("拼"));
        QVERIFY(!input.selectPreview(QStringLiteral("arbitrary-command")));
        klde::LocaleVoiceModel language;
        for (const auto &method : input.methods())
            QVERIFY(!language.text(method.toMap().value("labelId").toString()).startsWith('['));
    }
    void weatherUsesOwnedConditionVocabulary() {
        klde::WeatherReading reading;
        reading.category = klde::normalizeWeatherCondition(QStringLiteral("小雨"));
        QCOMPARE(reading.category, klde::WeatherCondition::Rain);
        QCOMPARE(reading.conditionId(), QStringLiteral("weather.condition.rain"));
        reading.category =
            klde::normalizeWeatherCondition(QStringLiteral("new provider-specific phrase"));
        QCOMPARE(reading.category, klde::WeatherCondition::Unknown);
        QCOMPARE(reading.conditionId(), QStringLiteral("weather.condition.unknown"));
    }
};
QTEST_GUILESS_MAIN(LocaleInputTest)
#include "test_locale_input.moc"
