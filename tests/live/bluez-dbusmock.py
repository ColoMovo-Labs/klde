#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""BluetoothSource: adapter discovery, connected devices and the Bluetooth switch."""
import sys

import dbus
import dbusmock

import liveprobe

ADDRESS = '11:22:33:44:55:66'


def main():
    liveprobe.start_bus()
    bluez_process, bluez = liveprobe.spawn('bluez5')
    mock = dbus.Interface(bluez, 'org.bluez.Mock')
    probe = liveprobe.Probe(sys.argv[1], 'bluetooth')
    try:
        # No adapter yet: unavailable, never the fixture's "on".
        probe.expect('bluetooth=false enabled=false connectedDevices=0')
        mock.AddAdapter('hci0', 'owode-ci')
        probe.expect('bluetooth=true enabled=true connectedDevices=0')
        mock.AddDevice('hci0', ADDRESS, 'Headphones')
        mock.ConnectDevice('hci0', ADDRESS)
        probe.expect('bluetooth=true enabled=true connectedDevices=1')
        probe.request('bluetooth.enabled', False)
        probe.expect('bluetooth=true enabled=false connectedDevices=0')
        probe.request('bluetooth.enabled', True)
        probe.expect('bluetooth=true enabled=true connectedDevices=1')
    finally:
        probe.close()
        bluez_process.terminate()
        bluez_process.wait(timeout=10)
        liveprobe.stop_bus()
    print('BlueZ live source followed adapters, devices and the Bluetooth switch')


if __name__ == '__main__':
    main()
