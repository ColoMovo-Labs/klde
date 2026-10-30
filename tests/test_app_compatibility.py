# SPDX-License-Identifier: GPL-3.0-or-later
"""Check process-local identity without altering host/session/portal state."""
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

WRAPPER = Path(__file__).resolve().parents[1] / 'packaging/owode-run'


class ApplicationCompatibilityTest(unittest.TestCase):
    def test_profiles_preserve_session_and_argument_boundaries(self):
        probe = 'import os,sys,json;print(json.dumps({"env":dict(os.environ),"args":sys.argv[1:]}))'
        env = dict(os.environ, XDG_CURRENT_DESKTOP='owoDE', XDG_SESSION_DESKTOP='owoDE',
                   WAYLAND_DISPLAY='private-test-socket', DISPLAY=':123',
                   DBUS_SESSION_BUS_ADDRESS='unix:path=/private-test-bus')
        for profile, expected in [('--gnome', 'GNOME'), ('--kde', 'KDE'), ('--native', 'owoDE')]:
            result = subprocess.run(['bash', str(WRAPPER), profile, '--', sys.executable, '-c', probe,
                                     'two words', '$literal;no-shell'], env=env, text=True,
                                    check=True, capture_output=True)
            state = json.loads(result.stdout)
            self.assertEqual(state['env']['XDG_CURRENT_DESKTOP'], expected)
            for name in ['XDG_SESSION_DESKTOP', 'WAYLAND_DISPLAY', 'DISPLAY', 'DBUS_SESSION_BUS_ADDRESS']:
                self.assertEqual(state['env'][name], env[name])
            self.assertEqual(state['args'], ['two words', '$literal;no-shell'])
            self.assertEqual(env['XDG_CURRENT_DESKTOP'], 'owoDE')

    def test_unknown_profile_and_empty_command_fail(self):
        for args in [['--other', '--', 'true'], ['--kde']]:
            result = subprocess.run(['bash', str(WRAPPER), *args], capture_output=True)
            self.assertEqual(result.returncode, 2)


if __name__ == '__main__':
    unittest.main()
