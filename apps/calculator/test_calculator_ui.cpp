// SPDX-License-Identifier: GPL-3.0-or-later
#include <QQmlApplicationEngine>
#include <QQuickItem>
#include <QQuickWindow>
#include <QtQml/QQmlExtensionPlugin>
#include <QtTest>

Q_IMPORT_QML_PLUGIN(OwoCalculatorPlugin)

class CalculatorUiTest : public QObject {
    Q_OBJECT
  private slots:
    void keyboardAndButtons() {
        QQmlApplicationEngine engine;
        engine.loadFromModule("OwoDE.Calculator", "Main");
        QCOMPARE(engine.rootObjects().size(), 1);
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        QVERIFY(window);
        QVERIFY(QTest::qWaitForWindowExposed(window));
        auto *expression = window->findChild<QQuickItem *>("calculatorExpression");
        QVERIFY(expression);
        expression->forceActiveFocus(Qt::TabFocusReason);
        QTest::keyClick(window, Qt::Key_2);
        QTest::keyClick(window, Qt::Key_Plus);
        QTest::keyClick(window, Qt::Key_3);
        QTest::keyClick(window, Qt::Key_Return);
        QTRY_COMPARE(expression->property("text").toString(), QString("5"));
        for (const auto &key :
             {QString("C"), QString("9"), QString("×"), QString("8"), QString("=")}) {
            auto *button = window->findChild<QQuickItem *>("calculatorKey-" + key);
            QVERIFY(button);
            QTest::mouseClick(
                window, Qt::LeftButton, Qt::NoModifier,
                button->mapToScene(QPointF(button->width() / 2, button->height() / 2)).toPoint());
        }
        QTRY_COMPARE(expression->property("text").toString(), QString("72"));
        QTest::keyClick(window, Qt::Key_Escape);
        QTRY_VERIFY(expression->property("text").toString().isEmpty());
    }
};
QTEST_MAIN(CalculatorUiTest)
#include "test_calculator_ui.moc"
