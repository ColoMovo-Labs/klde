// SPDX-License-Identifier: GPL-3.0-or-later
// Runs one live source against a private python-dbusmock system bus and prints
// the projected state on every change, one line per state. Lines on stdin of
// the form "set PATH true|false" go through SystemStateModel::requestValue, so
// the scripts exercise the same write route as the shell's switches.
#include "live/UPowerBatterySource.h"
#include "mock/SystemStateModel.h"
#include <QCoreApplication>
#include <QSocketNotifier>
#include <QTextStream>
#include <memory>
#include <unistd.h>
#if defined(OWODE_HAVE_NETWORKMANAGER)
#include "live/NetworkManagerSource.h"
#endif
#if defined(OWODE_HAVE_BLUEZ)
#include "live/BluetoothSource.h"
#endif

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    const auto args = QCoreApplication::arguments();
    if (qEnvironmentVariableIsEmpty("DBUS_SYSTEM_BUS_ADDRESS") || args.size() != 2)
        return 2;
    const QString mode = args.at(1);
    klde::SystemStateModel state;
    std::unique_ptr<QObject> source;
    QStringList paths;
    if (mode == QLatin1String("battery")) {
        auto battery = std::make_unique<klde::UPowerBatterySource>(&state);
        battery->start();
        source = std::move(battery);
        paths = {"capabilities.battery", "battery.percent", "battery.charging"};
#if defined(OWODE_HAVE_NETWORKMANAGER)
    } else if (mode == QLatin1String("network")) {
        auto network = std::make_unique<klde::NetworkManagerSource>(&state);
        network->start();
        source = std::move(network);
        paths = {"network.enabled", "network.connected", "network.internet", "network.ssid",
                 "network.strength"};
#endif
#if defined(OWODE_HAVE_BLUEZ)
    } else if (mode == QLatin1String("bluetooth")) {
        auto bluetooth = std::make_unique<klde::BluetoothSource>(&state);
        bluetooth->start();
        source = std::move(bluetooth);
        paths = {"capabilities.bluetooth", "bluetooth.enabled", "bluetooth.connectedDevices"};
#endif
    } else {
        return 3;
    }
    QTextStream out(stdout);
    QString last;
    const auto report = [&] {
        QStringList parts;
        for (const auto &path : std::as_const(paths)) {
            const auto value = state.value(path);
            const auto text = value.metaType().id() == QMetaType::Bool
                                  ? QString::fromLatin1(value.toBool() ? "true" : "false")
                                  : value.toString();
            parts.append(path.section('.', -1) + '=' + text);
        }
        const auto line = parts.join(' ');
        if (line != last) {
            last = line;
            out << line << Qt::endl;
        }
    };
    QObject::connect(&state, &klde::SystemStateModel::changed, &app, report);
    QSocketNotifier input(STDIN_FILENO, QSocketNotifier::Read);
    QTextStream commands(stdin);
    QObject::connect(&input, &QSocketNotifier::activated, &app, [&] {
        const auto words = commands.readLine().split(' ', Qt::SkipEmptyParts);
        if (words.size() == 3 && words.at(0) == QLatin1String("set"))
            out << "request="
                << (state.requestValue(words.at(1), words.at(2) == "true") ? "ok" : "refused")
                << Qt::endl;
    });
    report();
    return QCoreApplication::exec();
}
