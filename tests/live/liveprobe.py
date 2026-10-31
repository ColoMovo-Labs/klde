# SPDX-License-Identifier: GPL-3.0-or-later
"""Shared driver for live_probe: a private dbusmock system bus and line matching."""
import selectors
import subprocess
import time

import dbusmock

LINE_TIMEOUT = 15


class Probe:
    def __init__(self, binary, mode):
        self.process = subprocess.Popen([binary, mode], stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, text=True)
        self.selector = selectors.DefaultSelector()
        self.selector.register(self.process.stdout, selectors.EVENT_READ)

    def readline(self):
        """One line, or '' after LINE_TIMEOUT seconds so a stuck mock fails fast."""
        deadline = time.monotonic() + LINE_TIMEOUT
        while time.monotonic() < deadline:
            if self.selector.select(timeout=max(0.0, deadline - time.monotonic())):
                return self.process.stdout.readline().strip()
        return ''

    def expect(self, wanted, limit=80):
        for _ in range(limit):
            line = self.readline()
            if not line:
                break
            print('probe:', line, flush=True)
            if line == wanted:
                return
        raise SystemExit(f'probe never reported {wanted!r}')

    def expect_fields(self, limit=80, **wanted):
        """Wait for a line whose key=value fields include every wanted pair."""
        expected = {key: ('true' if value is True else 'false' if value is False else str(value))
                    for key, value in wanted.items()}
        for _ in range(limit):
            line = self.readline()
            if not line:
                break
            print('probe:', line, flush=True)
            fields = dict(part.split('=', 1) for part in line.split(' ') if '=' in part)
            if all(fields.get(key) == value for key, value in expected.items()):
                return
        raise SystemExit(f'probe never reported {expected!r}')

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
