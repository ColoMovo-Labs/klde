// SPDX-License-Identifier: GPL-3.0-or-later
#include "ShortcutRegistry.h"

#include <QKeySequence>

namespace klde {
ShortcutRegistry::ShortcutRegistry(QObject *parent) : QObject(parent) {
    m_actions = {
        {QStringLiteral("shell.launcher"), tr("Launcher"), QStringLiteral("Ctrl+Space"), {}},
        {QStringLiteral("shell.quick-settings"), tr("Quick Settings"), QStringLiteral("F2"), {}},
        {QStringLiteral("preview.blur-lab"),
         tr("Blur laboratory"),
         QStringLiteral("Ctrl+Alt+B"),
         {}},
        {QStringLiteral("effects.reduced-motion"),
         tr("Reduced motion"),
         QStringLiteral("Ctrl+Alt+R"),
         {}},
    };
    resetDefaults();
}

QVariantList ShortcutRegistry::actions() const {
    QVariantList result;
    for (const auto &action : m_actions) {
        result.append(QVariantMap{{QStringLiteral("id"), action.id},
                                  {QStringLiteral("label"), action.label},
                                  {QStringLiteral("sequence"), action.sequence},
                                  {QStringLiteral("defaultSequence"), action.defaultSequence},
                                  {QStringLiteral("scope"), QStringLiteral("application")}});
    }
    return result;
}

QString ShortcutRegistry::sequence(const QString &actionId) const {
    for (const auto &action : m_actions) {
        if (action.id == actionId) {
            return action.sequence;
        }
    }
    return {};
}

bool ShortcutRegistry::rebind(const QString &actionId, const QString &portableSequence) {
    auto action = m_actions.begin();
    while (action != m_actions.end() && action->id != actionId) {
        ++action;
    }
    if (action == m_actions.end()) {
        setError(tr("Unknown shortcut action."));
        return false;
    }

    const QString input = portableSequence.trimmed();
    QString normalized;
    if (!input.isEmpty()) {
        const auto parsed = QKeySequence::fromString(input, QKeySequence::PortableText);
        if (parsed.count() != 1 || parsed[0].key() == Qt::Key_unknown ||
            parsed[0].key() == Qt::Key(0)) {
            setError(tr("Enter one valid shortcut using PortableText, such as Ctrl+Alt+L."));
            return false;
        }
        const auto combination = parsed[0];
        const bool functionKey =
            combination.key() >= Qt::Key_F1 && combination.key() <= Qt::Key_F35;
        const bool commandModifier =
            combination.keyboardModifiers().testFlag(Qt::ControlModifier) ||
            combination.keyboardModifiers().testFlag(Qt::AltModifier) ||
            combination.keyboardModifiers().testFlag(Qt::MetaModifier);
        if (!functionKey && !commandModifier) {
            setError(
                tr("Use Ctrl, Alt or Meta with ordinary keys so search typing remains usable."));
            return false;
        }
        normalized = parsed.toString(QKeySequence::PortableText);
        for (const auto &existing : m_actions) {
            if (existing.id != actionId && existing.sequence == normalized) {
                setError(tr("That shortcut is already assigned to %1.").arg(existing.label));
                return false;
            }
        }
    }

    setError({});
    if (action->sequence != normalized) {
        action->sequence = normalized;
        emit bindingsChanged();
    }
    return true;
}

void ShortcutRegistry::resetDefaults() {
    bool changed = false;
    for (auto &action : m_actions) {
        if (action.sequence != action.defaultSequence) {
            action.sequence = action.defaultSequence;
            changed = true;
        }
    }
    setError({});
    if (changed) {
        emit bindingsChanged();
    }
}

void ShortcutRegistry::setError(const QString &message) {
    if (m_lastError != message) {
        m_lastError = message;
        emit lastErrorChanged();
    }
}
} // namespace klde
