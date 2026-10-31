# SPDX-License-Identifier: GPL-3.0-or-later
"""Shared driver for live_probe: a private dbusmock system bus and line matching."""
import subprocess

import dbusmock


class Probe:
    def __init__(self, binary, mode):
        self.process = subprocess.Popen([binary, mode], stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, text=True)

    def expect(self, wanted, limit=80):
        for _ in range(limit):
            line = self.process.stdout.readline().strip()
            if not line:
                break
            print('probe:', line, flush=True)
            if line == wanted:
                return
        raise SystemExit(f'probe never reported {wanted!r}')

    def request(self, path, value):
        self.process.stdin.write(f'set {path} {"true" if value else "false"}\n')
        self.process.stdin.flush()
        self.expect('request=ok')

    def close(self):
        self.process.terminate()
        self.process.wait(timeout=10)


def start_bus():
    dbusmock.DBusTestCase.start_system_bus()


def stop_bus():
    dbusmock.DBusTestCase.tearDownClass()


def spawn(template, parameters=None):
    return dbusmock.DBusTestCase.spawn_server_template(template, parameters or {},
                                                       stdout=subprocess.DEVNULL)
