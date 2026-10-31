#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Drive UPowerBatterySource against a private python-dbusmock system bus.

Covers the initial asynchronous snapshot, PropertiesChanged updates and a
UPower restart (owner change). The host system bus is never contacted.
"""
import subprocess
import sys

import dbus
import dbusmock

DISPLAY_DEVICE = '/org/freedesktop/UPower/devices/DisplayDevice'
BATTERY, DISCHARGING, CHARGING = 2, 2, 1


class Probe:
    def __init__(self, binary):
        self.process = subprocess.Popen([binary], stdout=subprocess.PIPE, text=True)

    def expect(self, wanted, limit=50):
        for _ in range(limit):
            line = self.process.stdout.readline().strip()
            if not line:
                break
            print('probe:', line, flush=True)
            if line == wanted:
                return
        raise SystemExit(f'probe never reported {wanted!r}')

    def close(self):
        self.process.terminate()
        self.process.wait(timeout=10)


def spawn_upower(percentage, state):
    process, manager = dbusmock.DBusTestCase.spawn_server_template(
        'upower', {'DaemonVersion': '1.90', 'OnBattery': state == DISCHARGING},
        stdout=subprocess.DEVNULL)
    manager.SetupDisplayDevice(BATTERY, state, percentage, 30.0, 60.0, 8.0, 3600, 0,
                               True, 'battery-good-symbolic', 1,
                               dbus_interface=dbusmock.MOCK_IFACE)
    return process, manager


def main():
    if len(sys.argv) != 2:
        raise SystemExit('usage: upower-dbusmock.py PROBE')
    dbusmock.DBusTestCase.start_system_bus()
    upower, manager = spawn_upower(57.0, DISCHARGING)
    probe = Probe(sys.argv[1])
    try:
        probe.expect('available=true percent=57 charging=false')
        manager.SetDeviceProperties(DISPLAY_DEVICE,
                                    {'Percentage': dbus.Double(41.0, variant_level=1),
                                     'State': dbus.UInt32(CHARGING, variant_level=1)},
                                    dbus_interface=dbusmock.MOCK_IFACE)
        probe.expect('available=true percent=41 charging=true')
        upower.terminate()
        upower.wait(timeout=10)
        upower, manager = spawn_upower(88.0, DISCHARGING)
        probe.expect('available=true percent=88 charging=false')
    finally:
        probe.close()
        upower.terminate()
        upower.wait(timeout=10)
        dbusmock.DBusTestCase.tearDownClass()
    print('UPower live battery source followed snapshot, changes and restart')


if __name__ == '__main__':
    main()
