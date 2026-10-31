// SPDX-License-Identifier: GPL-3.0-or-later
// Prints the projected battery state on every change, one line per state, for
// tests/live/upower-dbusmock.py. It never connects to the host system bus:
// the script points DBUS_SYSTEM_BUS_ADDRESS at a private dbusmock bus.
#include "live/UPowerBatterySource.h"
#include "mock/SystemStateModel.h"
#include <QCoreApplication>
#include <QTextStream>

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    if (qEnvironmentVariableIsEmpty("DBUS_SYSTEM_BUS_ADDRESS"))
        return 2;
    klde::SystemStateModel state;
    klde::UPowerBatterySource battery(&state);
    QString last;
    QTextStream out(stdout);
    const auto text = [](bool value) {
        return value ? QStringLiteral("true") : QStringLiteral("false");
    };
    const auto report = [&] {
        const auto line = QStringLiteral("available=%1 percent=%2 charging=%3")
                              .arg(text(state.value("capabilities.battery").toBool()))
                              .arg(state.value("battery.percent").toInt())
                              .arg(text(state.value("battery.charging").toBool()));
        if (line != last) {
            last = line;
            out << line << Qt::endl;
        }
    };
    QObject::connect(&state, &klde::SystemStateModel::changed, &app, report);
    battery.start();
    report();
    return QCoreApplication::exec();
}
