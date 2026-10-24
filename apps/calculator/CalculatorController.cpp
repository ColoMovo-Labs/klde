// SPDX-License-Identifier: GPL-3.0-or-later
#include "CalculatorController.h"
#include "evaluator.h"
#include <QCoreApplication>
#include <QLocale>
#include <QRegularExpression>
#include <QVariant>
#include <cstdlib>

namespace owode {
CalculatorController::CalculatorController(QObject *parent)
    : QObject(parent), m_evaluator(std::make_unique<Evaluator>()) {}
CalculatorController::~CalculatorController() = default;
bool CalculatorController::dark() const { return qApp->property("owodeDark").toBool(); }
bool CalculatorController::chinese() const {
    const auto locale = qApp->property("owodeLocale").toString();
    return locale.isEmpty() ? QLocale::system().language() == QLocale::Chinese : locale == "zh_CN";
}
QString CalculatorController::wallpaper() const {
    const auto value = qApp->property("owodeWallpaper").toString();
    return value.isEmpty() ? QStringLiteral("snow") : value;
}
void CalculatorController::clear() {
    m_result.clear();
    m_error.clear();
    emit changed();
}
bool CalculatorController::evaluate(const QString &expression) {
    clear();
    auto input = expression.trimmed();
    input.replace(QChar(0x00d7), '*');
    input.replace(QChar(0x00f7), '/');
    input.replace(QChar(0x2212), '-');
    // This first port deliberately exposes basic arithmetic only. Keep scientific
    // functions/assignment and unbounded factorial/exponent work out of the UI.
    static const QRegularExpression allowed(QStringLiteral("^[0-9+*/().%\\s-]+$"));
    if (input.isEmpty() || input.size() > 256 || !allowed.match(input).hasMatch()) {
        m_error = chinese() ? QStringLiteral("请输入不超过 256 字的基本算式。")
                            : QStringLiteral("Enter a basic expression of at most 256 characters.");
        emit changed();
        return false;
    }
    m_evaluator->setExpression(input);
    const auto value = m_evaluator->eval();
    if (!m_evaluator->error().isEmpty() || value.isNan()) {
        // The evaluator's diagnostic can contain the expression. Do not log it.
        m_error = chinese() ? QStringLiteral("无法计算，请检查算式。")
                            : QStringLiteral("Unable to calculate. Check the expression.");
        emit changed();
        return false;
    }
    const std::unique_ptr<char, decltype(&std::free)> formatted(HMath::formatFixed(value),
                                                                &std::free);
    if (!formatted) {
        m_error = chinese() ? QStringLiteral("无法格式化结果。")
                            : QStringLiteral("Unable to format the result.");
        emit changed();
        return false;
    }
    m_result = QString::fromLatin1(formatted.get());
    emit changed();
    return true;
}
} // namespace owode
