// SPDX-License-Identifier: GPL-3.0-or-later
#include "CalculatorController.h"
#include <QtTest>

class CalculatorTest : public QObject {
    Q_OBJECT
  private slots:
    void arithmetic_data() {
        QTest::addColumn<QString>("expression");
        QTest::addColumn<QString>("expected");
        QTest::newRow("precedence") << "2+3*4" << "14";
        QTest::newRow("parentheses") << "(2+3)*4" << "20";
        QTest::newRow("decimal") << "0.1+0.2" << "0.3";
        QTest::newRow("unicode") << "8÷2×3−1" << "11";
        QTest::newRow("negative") << "-5+2" << "-3";
    }
    void arithmetic() {
        QFETCH(QString, expression);
        QFETCH(QString, expected);
        owode::CalculatorController calculator;
        QVERIFY(calculator.evaluate(expression));
        QCOMPARE(calculator.result(), expected);
        QVERIFY(calculator.error().isEmpty());
    }
    void invalidAndRecovery() {
        owode::CalculatorController calculator;
        for (const auto &input : {QString(), QString("1/0"), QString("2+"), QString("999!"),
                                  QString("2^999999"), QString(257, '9')}) {
            QVERIFY(!calculator.evaluate(input));
            QVERIFY(!calculator.error().isEmpty());
            QVERIFY(calculator.result().isEmpty());
        }
        QVERIFY(calculator.evaluate("6*7"));
        QCOMPARE(calculator.result(), QString("42"));
        QVERIFY(calculator.error().isEmpty());
    }
};
QTEST_GUILESS_MAIN(CalculatorTest)
#include "test_calculator.moc"
