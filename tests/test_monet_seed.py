#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Contract tests for the dependency-free owoDE wallpaper seed extractor."""

from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("owode_monet_seed", ROOT / "tools/extract-monet-seed.py")
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


def write_ppm(path: Path) -> None:
    # A neutral sky dominates the image, while a smaller saturated accent is
    # the meaningful seed. A simple frequency-only picker would choose blue.
    pixels = [(190, 210, 228)] * 144 + [(236, 92, 132)] * 112
    path.write_bytes(
        b"P6\n16 16\n255\n" + b"".join(bytes(pixel) for pixel in pixels)
    )


def main() -> None:
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "fixture.ppm"
        write_ppm(path)
        pixels = module.load_pixels(path)
        first, metadata = module.extract_seed(pixels)
        second, same_metadata = module.extract_seed(pixels)
        assert first == second == "#e85888", (first, metadata)
        assert metadata == same_metadata
        assert metadata["method"] == "quantized-prominent-chroma-v1"

        # The CLI's JSON shape is intentionally small and stable for a future
        # settings/cache backend to consume.
        assert json.loads(json.dumps({"seed": first, **metadata}))["seed"] == first
    print("validated deterministic prominent-chroma Monet seed extraction")


if __name__ == "__main__":
    main()
