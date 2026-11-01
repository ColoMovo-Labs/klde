# SPDX-License-Identifier: GPL-3.0-or-later
"""Source/provenance contract; real greeter loading is a separate cloud gate."""
import hashlib
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / 'packaging/lockscreen/org.owode.shell'


class LockerContract(unittest.TestCase):
    def test_upstream_authentication_presentation_is_unchanged(self):
        manifest = json.loads((PACKAGE.parent / 'upstream.json').read_text())
        self.assertEqual(manifest['license'], 'GPL-2.0-or-later')
        self.assertEqual(manifest['commit'], '057b3774d9ad322cfccc2683ea057aed87e0f878')
        for name, expected in manifest['files_sha256'].items():
            content = (PACKAGE / 'contents/lockscreen' / name).read_bytes()
            self.assertEqual(hashlib.sha256(content).hexdigest(), expected)
            self.assertIn(b'SPDX-License-Identifier: GPL-2.0-or-later', content)

    def test_package_uses_supported_shell_api_without_the_missing_session_plugin(self):
        metadata = json.loads((PACKAGE / 'metadata.json').read_text())
        self.assertEqual(metadata['KPlugin']['Id'], 'org.owode.shell')
        self.assertEqual(metadata['KPackageStructure'], 'Plasma/Shell')
        self.assertEqual(metadata['X-Plasma-APIVersion'], '2')
        wrapper = (PACKAGE / 'contents/lockscreen/LockScreen.qml').read_text()
        wrapper = re.sub(r'//[^\n]*', '', wrapper)
        self.assertNotIn('org.kde.plasma.private.sessions', wrapper)
        self.assertNotIn('Qt.quit(', wrapper)
        self.assertNotIn('authenticator.', wrapper)
        self.assertIn('Greeter {', wrapper)
        self.assertTrue((ROOT / 'LICENSES/GPL-2.0-or-later.txt').is_file())

    def test_theme_choice_is_scoped_to_the_session_launcher(self):
        starter = (ROOT / 'packaging/session/start-owode').read_text()
        self.assertIn('export PLASMA_DEFAULT_SHELL=org.owode.shell', starter)
        self.assertNotIn('kwriteconfig', starter)
        self.assertNotIn('RequirePassword=false', starter)


if __name__ == '__main__':
    unittest.main()
