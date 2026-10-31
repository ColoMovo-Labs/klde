#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""NetworkManagerSource: Wi-Fi snapshot, signal strength, the Wi-Fi switch and offline."""
import sys

import dbus
import dbusmock

import liveprobe

NM = '/org/freedesktop/NetworkManager'
NM_IFACE = 'org.freedesktop.NetworkManager'
AP_IFACE = 'org.freedesktop.NetworkManager.AccessPoint'
DEVICE_ACTIVATED, ACTIVE_CONNECTION_ACTIVATED = 100, 2
STATE_CONNECTED_GLOBAL, STATE_DISCONNECTED = 70, 20
CONNECTIVITY_FULL, CONNECTIVITY_NONE = 4, 1


def main():
    liveprobe.start_bus()
    nm_process, nm = liveprobe.spawn('networkmanager')
    probe = None
    try:
        mock = dbus.Interface(nm, dbusmock.MOCK_IFACE)
        device = mock.AddWiFiDevice('mock_wifi0', 'wlan0', DEVICE_ACTIVATED)
        # The SSID is network-controlled text; control characters must not survive.
        ssid = 'Snowline\x07'
        ap = mock.AddAccessPoint(device, 'mock_ap0', ssid, '00:23:F8:7E:12:BB', 2, 2425, 5400,
                                 82, 0x400)
        connection = mock.AddWiFiConnection(device, 'mock_con0', ssid, 'wpa-psk')
        active = mock.AddActiveConnection([device], connection, ap, 'mock_active0',
                                          ACTIVE_CONNECTION_ACTIVATED)
        mock.SetProperty(NM, NM_IFACE, 'PrimaryConnection', dbus.ObjectPath(active))
        mock.SetGlobalConnectionState(STATE_CONNECTED_GLOBAL)
        mock.SetConnectivity(CONNECTIVITY_FULL)
        probe = liveprobe.Probe(sys.argv[1], 'network')
        probe.expect('enabled=true connected=true internet=true ssid=Snowline strength=82')
        mock.SetProperty(ap, AP_IFACE, 'Strength', dbus.Byte(41))
        probe.expect('enabled=true connected=true internet=true ssid=Snowline strength=41')
        probe.request('network.enabled', False)
        probe.expect('enabled=false connected=true internet=true ssid=Snowline strength=41')
        mock.SetGlobalConnectionState(STATE_DISCONNECTED)
        mock.SetConnectivity(CONNECTIVITY_NONE)
        probe.expect('enabled=false connected=false internet=false ssid= strength=0')
    finally:
        if probe:
            probe.close()
        nm_process.terminate()
        nm_process.wait(timeout=10)
        liveprobe.stop_bus()
    print('NetworkManager live source followed state, strength and the Wi-Fi switch')


if __name__ == '__main__':
    main()
