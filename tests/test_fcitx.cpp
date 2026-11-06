// SPDX-License-Identifier: GPL-3.0-or-later
#include "input/Fcitx5Backend.h"
#include "mock/SystemStateModel.h"
#include <QDBusArgument>
#include <QDBusContext>
#include <QDBusMetaType>
#include <QSignalSpy>
#include <QtTest>

struct MethodEntry {
    QString id, name, nativeName, icon, label, language, addon;
    bool configurable = true;
    QString layout;
    QVariantMap options;
};
using MethodEntries = QList<MethodEntry>;
Q_DECLARE_METATYPE(MethodEntry)
Q_DECLARE_METATYPE(MethodEntries)
QDBusArgument &operator<<(QDBusArgument &argument, const MethodEntry &method) {
    argument.beginStructure();
    argument << method.id << method.name << method.nativeName << method.icon << method.label
             << method.language << method.addon << method.configurable << method.layout
             << method.options;
    argument.endStructure();
    return argument;
}
const QDBusArgument &operator>>(const QDBusArgument &argument, MethodEntry &method) {
    argument.beginStructure();
    argument >> method.id >> method.name >> method.nativeName >> method.icon >> method.label >>
        method.language >> method.addon >> method.configurable >> method.layout >> method.options;
    argument.endStructure();
    return argument;
}
class FcitxFixture final : public QObject, protected QDBusContext {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.fcitx.Fcitx.Controller1")
  public:
    QString current = QStringLiteral("keyboard-us");
    bool reject = false;
    int switches = 0;
    MethodEntries entries;
  public slots:
    QString FullInputMethodGroupInfo(const QString &, QString &defaultMethod, QString &layout,
                                     QVariantMap &options, MethodEntries &methods) const {
        defaultMethod = QStringLiteral("pinyin");
        layout = QStringLiteral("us");
        options.clear();
        methods = entries;
        return QStringLiteral("Fixture");
    }
    QString CurrentInputMethod() const { return current; }
    void SetCurrentIM(const QString &id) {
        ++switches;
        if (reject) {
            sendErrorReply(QDBusError::Failed, QStringLiteral("Fixture rejected request"));
            return;
        }
        current = id;
    }
  signals:
    void InputMethodGroupsChanged();
};
class FcitxTests final : public QObject {
    Q_OBJECT
    QDBusConnection m_server =
        QDBusConnection::connectToBus(QDBusConnection::SessionBus, "fcitx-fixture");
    FcitxFixture m_fixture;
  private slots:
    void initTestCase() {
        qDBusRegisterMetaType<MethodEntry>();
        qDBusRegisterMetaType<MethodEntries>();
        MethodEntry english;
        english.id = QStringLiteral("keyboard-us");
        english.name = QStringLiteral("English");
        english.label = QStringLiteral("en");
        MethodEntry pinyin;
        pinyin.id = QStringLiteral("pinyin");
        pinyin.name = QStringLiteral("Pinyin");
        pinyin.nativeName = QStringLiteral("拼音");
        pinyin.label = QStringLiteral("拼");
        m_fixture.entries = {english, pinyin};
        QVERIFY(
            m_server.registerObject("/controller", &m_fixture, QDBusConnection::ExportAllContents));
    }
    void cleanup() { m_server.unregisterService("org.fcitx.Fcitx5"); }
    void nativeStatusAndAsynchronousControl() {
        klde::Fcitx5Backend input;
        input.start();
        QVERIFY(!input.simulated());
        QVERIFY(!input.engineAvailable());
        QVERIFY(input.methods().isEmpty());
        QVERIFY(!input.selectPreview(QStringLiteral("pinyin")));
        QVERIFY(m_server.registerService("org.fcitx.Fcitx5"));
        QTRY_VERIFY(input.switchingSupported());
        QCOMPARE(input.methods().size(), 2);
        QCOMPARE(input.currentId(), QStringLiteral("keyboard-us"));
        QCOMPARE(input.indicator(), QStringLiteral("EN"));
        QVERIFY(input.requestSwitch(QStringLiteral("pinyin")));
        QTRY_COMPARE(input.currentId(), QStringLiteral("pinyin"));
        QCOMPARE(input.indicator(), QStringLiteral("拼"));
        QVERIFY(!input.requestSwitch(QStringLiteral("not-configured")));
        m_fixture.reject = true;
        QSignalSpy rejected(&input, &klde::InputMethodBackend::requestRejected);
        QVERIFY(input.requestSwitch(QStringLiteral("keyboard-us")));
        QTRY_COMPARE(rejected.size(), 1);
        QCOMPARE(input.currentId(), QStringLiteral("pinyin"));
        m_fixture.reject = false;
        MethodEntry japanese;
        japanese.id = QStringLiteral("mozc");
        japanese.nativeName = QStringLiteral("日本語");
        japanese.label = QStringLiteral("あ");
        m_fixture.entries.append(japanese);
        m_fixture.current = QStringLiteral("mozc");
        emit m_fixture.InputMethodGroupsChanged();
        QTRY_COMPARE(input.methods().size(), 3);
        QTRY_COMPARE(input.currentId(), QStringLiteral("mozc"));
        QCOMPARE(input.indicator(), QStringLiteral("あ"));
        m_fixture.entries.removeLast();
        m_server.unregisterService("org.fcitx.Fcitx5");
        QTRY_VERIFY(!input.engineAvailable());
        QVERIFY(input.methods().isEmpty());
        QVERIFY(!input.switchingSupported());
        QCOMPARE(input.indicator(), QStringLiteral("—"));
    }
    void nativeIdDoesNotLoosenMockEditValidation() {
        klde::SystemStateModel state;
        QVERIFY(!state.requestValue("input.currentId", QStringLiteral("mozc")));
        QVERIFY(state.publishLive("input.currentId", QStringLiteral("mozc")));
        QCOMPARE(state.value("input.currentId").toString(), QStringLiteral("mozc"));
        QVERIFY(!state.requestValue("input.currentId", QStringLiteral("pinyin")));
    }
};
QTEST_GUILESS_MAIN(FcitxTests)
#include "test_fcitx.moc"
