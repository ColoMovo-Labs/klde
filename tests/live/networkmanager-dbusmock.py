#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""NetworkManagerSource: radio, connection and connectivity state, and the Wi-Fi switch.

SSID and signal strength are accepted on real hardware only: python-dbusmock's
NetworkManager template does not provide a primary connection that
NetworkManagerQt resolves, so those fields are not asserted here.
"""
import sys

import dbus
import dbusmock

import liveprobe

DEVICE_ACTIVATED = 100
STATE_CONNECTED_GLOBAL, STATE_DISCONNECTED = 70, 20
CONNECTIVITY_FULL, CONNECTIVITY_NONE = 4, 1


def main():
    liveprobe.start_bus()
    nm_process, nm = liveprobe.spawn('networkmanager')
    probe = None
    try:
        mock = dbus.Interface(nm, dbusmock.MOCK_IFACE)
        mock.AddWiFiDevice('mock_wifi0', 'wlan0', DEVICE_ACTIVATED)
        mock.SetGlobalConnectionState(STATE_CONNECTED_GLOBAL)
        mock.SetConnectivity(CONNECTIVITY_FULL)
        probe = liveprobe.Probe(sys.argv[1], 'network')
        probe.expect_fields(enabled=True, connected=True, internet=True)
        probe.request('network.enabled', False)
        probe.expect_fields(enabled=False)
        mock.SetGlobalConnectionState(STATE_DISCONNECTED)
        mock.SetConnectivity(CONNECTIVITY_NONE)
        probe.expect_fields(enabled=False, connected=False, internet=False)
    finally:
        if probe:
            probe.close()
        nm_process.terminate()
        nm_process.wait(timeout=10)
        liveprobe.stop_bus()
    print('NetworkManager live source followed state and the Wi-Fi switch')


if __name__ == '__main__':
    main()
