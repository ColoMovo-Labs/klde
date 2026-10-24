// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QtQml/qqmlregistration.h>
#include <memory>

class Evaluator;
namespace owode {
class CalculatorController final : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(Calculator)
    QML_SINGLETON
    Q_PROPERTY(QString result READ result NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(bool dark READ dark CONSTANT)
    Q_PROPERTY(bool chinese READ chinese CONSTANT)
    Q_PROPERTY(QString wallpaper READ wallpaper CONSTANT)
  public:
    explicit CalculatorController(QObject *parent = nullptr);
    ~CalculatorController() override;
    QString result() const { return m_result; }
    QString error() const { return m_error; }
    bool dark() const;
    bool chinese() const;
    QString wallpaper() const;
    Q_INVOKABLE bool evaluate(const QString &expression);
    Q_INVOKABLE void clear();
  signals:
    void changed();

  private:
    std::unique_ptr<Evaluator> m_evaluator;
    QString m_result;
    QString m_error;
};
} // namespace owode
