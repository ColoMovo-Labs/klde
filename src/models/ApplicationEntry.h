// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QString>

namespace klde {
struct ApplicationEntry {
    QString id;
    QString name;
    QString description;
    QString icon;
    QString keywords;
    bool running = false;
    bool active = false;
    QString origin = QStringLiteral("linux");
    bool pinned = false;
};
} // namespace klde
