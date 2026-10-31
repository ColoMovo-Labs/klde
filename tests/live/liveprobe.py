# SPDX-License-Identifier: GPL-3.0-or-later
"""Shared driver for live_probe: a private dbusmock system bus and line matching."""
import queue
import subprocess
import threading

import dbusmock

LINE_TIMEOUT = 15


class Probe:
    def __init__(self, binary, mode):
        self.process = subprocess.Popen([binary, mode], stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, text=True)
        # A reader thread keeps buffered lines visible; select() on a text
        # stream would miss lines Python has already read ahead.
        self.lines = queue.Queue()
        threading.Thread(target=self._read, daemon=True).start()

    def _read(self):
        for line in self.process.stdout:
            self.lines.put(line.strip())
        self.lines.put('')

    def readline(self):
        """One line, or '' after LINE_TIMEOUT seconds so a stuck mock fails fast."""
        try:
            return self.lines.get(timeout=LINE_TIMEOUT)
        except queue.Empty:
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
