# SPDX-License-Identifier: GPL-3.0-or-later
"""Regression: consecutive native engines recycle layer-shell object IDs."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "native_protocol", Path(__file__).resolve().parents[1] / "tools/verify-native-protocol.py")
protocol = importlib.util.module_from_spec(spec)
spec.loader.exec_module(protocol)


def surface(identifier, layer, namespace, anchor, zone, keyboard):
    return f''' -> zwlr_layer_shell_v1#43.get_layer_surface(new id zwlr_layer_surface_v1#{identifier}, wl_surface#46, wl_output#24, {layer}, "{namespace}")
 -> zwlr_layer_surface_v1#{identifier}.set_anchor({anchor})
 -> zwlr_layer_surface_v1#{identifier}.set_exclusive_zone({zone})
 -> zwlr_layer_surface_v1#{identifier}.set_keyboard_interactivity({keyboard})
 -> zwlr_layer_surface_v1#{identifier}.ack_configure(10)
 -> zwlr_layer_surface_v1#{identifier}.destroy()
'''


class NativeProtocolTest(unittest.TestCase):
    def setUp(self):
        self.first = (surface(49, 2, 'dock', 13, 80, 0)
                      + surface(50, 2, 'dock', 14, 0, 0)
                      + surface(51, 0, 'desktop', 15, -1, 0)
                      + surface(52, 3, 'on-screen-display', 15, -1, 1))

    def test_recycled_id_can_change_from_ribbon_to_dock(self):
        second = surface(49, 2, 'dock', 14, 0, 0) + surface(50, 2, 'dock', 13, 80, 0)
        roles = protocol.inspect(self.first + second, 'recycled')
        self.assertEqual(len(roles['dock']), 2)
        self.assertEqual(len(roles['ribbon']), 2)

    def test_valid_first_lifetime_does_not_hide_broken_second(self):
        with self.assertRaisesRegex(ValueError, 'exclusive zone'):
            protocol.inspect(self.first + surface(49, 2, 'dock', 14, -1, 0), 'broken')

    def test_missing_configure_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'configure acknowledgement'):
            protocol.inspect(self.first.replace(' -> zwlr_layer_surface_v1#51.ack_configure(10)\n', ''), 'incomplete')


if __name__ == '__main__':
    unittest.main()
