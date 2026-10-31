#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""UPowerBatterySource: initial snapshot, PropertiesChanged and a UPower restart."""
import sys

import dbus
import dbusmock

import liveprobe

DISPLAY_DEVICE = '/org/freedesktop/UPower/devices/DisplayDevice'
BATTERY, CHARGING, DISCHARGING = 2, 1, 2


def spawn_upower(percentage, state):
    process, manager = liveprobe.spawn('upower', {'DaemonVersion': '1.90',
                                                  'OnBattery': state == DISCHARGING})
    manager.SetupDisplayDevice(BATTERY, state, percentage, 30.0, 60.0, 8.0, 3600, 0,
                               True, 'battery-good-symbolic', 1,
                               dbus_interface=dbusmock.MOCK_IFACE)
    return process, manager


def main():
    liveprobe.start_bus()
    upower, manager = spawn_upower(57.0, DISCHARGING)
    probe = liveprobe.Probe(sys.argv[1], 'battery')
    try:
        probe.expect('battery=true percent=57 charging=false')
        manager.SetDeviceProperties(DISPLAY_DEVICE,
                                    {'Percentage': dbus.Double(41.0, variant_level=1),
                                     'State': dbus.UInt32(CHARGING, variant_level=1)},
                                    dbus_interface=dbusmock.MOCK_IFACE)
        probe.expect('battery=true percent=41 charging=true')
        upower.terminate()
        upower.wait(timeout=10)
        upower, manager = spawn_upower(88.0, DISCHARGING)
        probe.expect('battery=true percent=88 charging=false')
    finally:
        probe.close()
        upower.terminate()
        upower.wait(timeout=10)
        liveprobe.stop_bus()
    print('UPower live battery source followed snapshot, changes and restart')


if __name__ == '__main__':
    main()
