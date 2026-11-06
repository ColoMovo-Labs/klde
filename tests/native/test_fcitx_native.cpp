// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShellServices.h"
#include <QApplication>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QInputMethodEvent>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QLineEdit>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QVBoxLayout>
#include <QtTest>

class InputField final : public QLineEdit {
  public:
    QString lastPreedit;

  protected:
    void inputMethodEvent(QInputMethodEvent *event) override {
        if (!event->preeditString().isEmpty())
            lastPreedit = event->preeditString();
        QLineEdit::inputMethodEvent(event);
    }
};
class NativeInputTest final : public QObject {
    Q_OBJECT
    QString m_output;
    bool parentCommand(const QString &program, const QStringList &args) const {
        QProcess process;
        auto environment = QProcessEnvironment::systemEnvironment();
        environment.insert("DISPLAY", qEnvironmentVariable("OWODE_INPUT_PARENT_DISPLAY"));
        process.setProcessEnvironment(environment);
        process.start(program, args);
        if (!process.waitForStarted(1000))
            return false;
        QElapsedTimer timer;
        timer.start();
        // Keep Qt's text-input event processing alive while physical keys arrive.
        while (process.state() != QProcess::NotRunning && timer.elapsed() < 5000)
            QTest::qWait(10);
        const bool success = process.state() == QProcess::NotRunning && process.exitCode() == 0;
        if (process.state() != QProcess::NotRunning) {
            process.kill();
            process.waitForFinished(1000);
        }
        if (!success)
            qWarning() << program << process.errorString() << process.readAllStandardError();
        return success;
    }
    bool capture(const QString &name) const {
        return parentCommand("magick",
                             {"import", "-window", "root", m_output + "/" + name + ".png"});
    }
  private slots:
    void nativePinyinAndTrayUpdates() {
        QVERIFY(qEnvironmentVariable("OWODE_CLOUD_FCITX_TEST") == "1");
        QVERIFY(QFile::exists("/.dockerenv"));
        QVERIFY(qEnvironmentVariable("XDG_RUNTIME_DIR").startsWith("/tmp/owode-input-ci-"));
        QCOMPARE(qEnvironmentVariable("WAYLAND_DISPLAY"), QString("owode-input-ci"));
        QCOMPARE(QGuiApplication::platformName(), QString("wayland"));
        QVERIFY(qEnvironmentVariableIsEmpty("QT_IM_MODULE"));
        m_output = qEnvironmentVariable("OWODE_INPUT_EVIDENCE");
        QVERIFY(!m_output.isEmpty());
        QQmlApplicationEngine engine;
        const QSignalSpy warnings(&engine, &QQmlApplicationEngine::warnings);
        engine.setProperty("owodeSystemApplications", true);
        engine.setInitialProperties({{"nativeSurfaceMode", true}, {"initialLocale", "zh_CN"}});
        engine.loadFromModule("KLDE.Shell", "Main");
        QCOMPARE(engine.rootObjects().size(), 1);
        auto *root = engine.rootObjects().front();
        auto *services = engine.singletonInstance<klde::ShellServices *>("KLDE.Backends", "Shell");
        QVERIFY(services);
        auto *input = services->input();
        QTRY_VERIFY_WITH_TIMEOUT(input->switchingSupported(), 15000);
        QVERIFY(!input->simulated());
        QTRY_VERIFY_WITH_TIMEOUT(!services->tray()->items().isEmpty(), 10000);
        QWidget window;
        window.setWindowTitle("owoDE native input verification");
        window.resize(640, 320);
        auto *layout = new QVBoxLayout(&window);
        layout->addWidget(new QLabel("Real Qt Wayland text input / 真正的拼音输入", &window));
        InputField field;
        layout->addWidget(&field);
        window.show();
        field.setFocus();
        QTRY_VERIFY(window.isActiveWindow());
        // The upstream launcher deliberately waits one second before reopening
        // its connection. Controller availability precedes that handover.
        QTest::qWait(1300);
        QVERIFY(input->requestSwitch("pinyin"));
        QTRY_COMPARE(input->currentId(), QString("pinyin"));
        const auto pinyinIndicator = input->indicator();
        QVERIFY(parentCommand("xdotool", {"type", "--clearmodifiers", "--delay", "80", "nihao"}));
        QTRY_VERIFY_WITH_TIMEOUT(!field.lastPreedit.isEmpty(), 5000);
        QVERIFY(field.text().isEmpty());
        QTest::qWait(200);
        QVERIFY(capture("pinyin-preedit"));
        QVERIFY(parentCommand("xdotool", {"key", "space"}));
        QTRY_COMPARE(field.text(), QString("你好"));
        QVERIFY(capture("pinyin-committed"));
        // No explicit refresh: a physical Fcitx shortcut must update the backend
        // through the notification item's public event, without polling.
        QVERIFY(parentCommand("xdotool", {"key", "ctrl+space"}));
        QTRY_COMPARE(input->currentId(), QString("keyboard-us"));
        QVERIFY(input->indicator() != pinyinIndicator);
        QVERIFY(QMetaObject::invokeMethod(root, "showView", Q_ARG(QString, QString("tray"))));
        auto *tray = root->findChild<QObject *>("trayPopup");
        QVERIFY(tray);
        QTRY_VERIFY(tray->property("opened").toBool());
        QTest::qWait(300);
        QVERIFY(capture("native-tray"));
        QFile evidence(m_output + "/input-result.json");
        QVERIFY(evidence.open(QIODevice::WriteOnly));
        evidence.write(QJsonDocument(QJsonObject{{"platform", QGuiApplication::platformName()},
                                                 {"text", field.text()},
                                                 {"preedit", field.lastPreedit},
                                                 {"methodAfterShortcut", input->currentId()},
                                                 {"indicatorAfterShortcut", input->indicator()},
                                                 {"trayItems", services->tray()->items().size()},
                                                 {"qtInputModuleOverride", false},
                                                 {"hardwareAcceptance", false}})
                           .toJson());
        QCOMPARE(warnings.count(), 0);
    }
};
QTEST_MAIN(NativeInputTest)
#include "test_fcitx_native.moc"
