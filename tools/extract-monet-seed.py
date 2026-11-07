#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Extract one stable, expressive wallpaper seed for owoDE.

This is intentionally a small dependency-free extractor. It follows the useful
idea seen in several modern Wayland shells: quantize the image, prefer a
prominent *colorful* sample over the largest neutral region, and only resolve
the palette once per wallpaper change. The actual semantic role generation
remains in ``design/Owo/Visuals/MonetPalette.qml``.

Supported inputs are PNG (8-bit RGB/RGBA, non-interlaced), PPM/PNM and SVG
files containing hex colors. Unsupported formats fail clearly so callers can
fall back to an authored seed instead of silently changing the theme.
"""

from __future__ import annotations

import argparse
import binascii
import colorsys
import json
import math
import re
import struct
import sys
import zlib
from collections import Counter
from pathlib import Path
from typing import Iterable, Sequence


RGB = tuple[int, int, int]


def _read_ppm(data: bytes) -> list[RGB]:
    tokens = re.findall(rb"[^\s#]+", data)
    if not tokens or tokens[0] not in {b"P3", b"P6"}:
        raise ValueError("not a PPM/PNM image")
    if len(tokens) < 4:
        raise ValueError("truncated PPM header")
    width, height, maximum = (int(tokens[i]) for i in (1, 2, 3))
    if width <= 0 or height <= 0 or maximum <= 0:
        raise ValueError("invalid PPM dimensions")
    if tokens[0] == b"P3":
        values = [int(value) for value in tokens[4:]]
        if len(values) < width * height * 3:
            raise ValueError("truncated P3 pixel data")
        raw = values[: width * height * 3]
    else:
        header_end = 0
        count = 0
        while count < 4:
            match = re.search(rb"\S+", data[header_end:])
            if not match:
                raise ValueError("truncated P6 header")
            header_end += match.end()
            count += 1
        while header_end < len(data) and data[header_end] in b" \t\r\n":
            header_end += 1
        raw_bytes = data[header_end:]
        if len(raw_bytes) < width * height * 3:
            raise ValueError("truncated P6 pixel data")
        raw = list(raw_bytes[: width * height * 3])
    scale = 255.0 / maximum
    return [
        (round(raw[i] * scale), round(raw[i + 1] * scale), round(raw[i + 2] * scale))
        for i in range(0, width * height * 3, 3)
    ]


def _png_unfilter(scanlines: bytes, width: int, height: int, channels: int) -> list[RGB]:
    stride = width * channels
    row_size = stride + 1
    if len(scanlines) < height * row_size:
        raise ValueError("truncated PNG scanlines")
    rows: list[bytes] = []
    previous = bytearray(stride)
    for row_index in range(height):
        offset = row_index * row_size
        filter_type = scanlines[offset]
        current = bytearray(scanlines[offset + 1 : offset + row_size])
        if len(current) != stride:
            raise ValueError("truncated PNG row")
        for i in range(stride):
            left = current[i - channels] if i >= channels else 0
            up = previous[i]
            upper_left = previous[i - channels] if i >= channels else 0
            if filter_type == 1:
                current[i] = (current[i] + left) & 0xFF
            elif filter_type == 2:
                current[i] = (current[i] + up) & 0xFF
            elif filter_type == 3:
                current[i] = (current[i] + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                estimate = left + up - upper_left
                pa = abs(estimate - left)
                pb = abs(estimate - up)
                pc = abs(estimate - upper_left)
                predictor = left if pa <= pb and pa <= pc else up if pb <= pc else upper_left
                current[i] = (current[i] + predictor) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"unsupported PNG filter {filter_type}")
        rows.append(bytes(current))
        previous = current
    pixels: list[RGB] = []
    for row in rows:
        for offset in range(0, len(row), channels):
            pixels.append((row[offset], row[offset + 1], row[offset + 2]))
    return pixels


def _read_png(data: bytes) -> list[RGB]:
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("not a PNG image")
    width = height = bit_depth = color_type = None
    idat = bytearray()
    offset = 8
    while offset + 12 <= len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload = data[offset + 8 : offset + 8 + length]
        offset += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
            if compression != 0 or filtering != 0 or interlace != 0:
                raise ValueError("PNG compression/filter/interlace mode is unsupported")
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            break
    if width is None or height is None or bit_depth != 8 or color_type not in {2, 6}:
        raise ValueError("PNG must be 8-bit RGB or RGBA")
    channels = 3 if color_type == 2 else 4
    return _png_unfilter(zlib.decompress(bytes(idat)), width, height, channels)


def _read_svg(data: bytes) -> list[RGB]:
    text = data.decode("utf-8", errors="ignore")
    values = re.findall(r"#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}\b", text)
    pixels: list[RGB] = []
    for value in values:
        digits = value[1:]
        if len(digits) == 3:
            digits = "".join(char * 2 for char in digits)
        pixels.append(tuple(int(digits[i : i + 2], 16) for i in (0, 2, 4)))
    if not pixels:
        raise ValueError("SVG contains no hex colors")
    # SVG colors are declarations rather than raster pixels. Repeat them to
    # make frequency meaningful while keeping the result deterministic.
    return pixels * 32


def load_pixels(path: Path) -> list[RGB]:
    data = path.read_bytes()
    suffix = path.suffix.lower()
    if suffix in {".ppm", ".pnm"}:
        return _read_ppm(data)
    if suffix == ".png" or data.startswith(b"\x89PNG"):
        return _read_png(data)
    if suffix == ".svg" or b"<svg" in data[:512].lower():
        return _read_svg(data)
    raise ValueError(f"unsupported wallpaper format: {path.suffix or '<none>'}")


def _sample(pixels: Sequence[RGB], limit: int = 20000) -> Iterable[RGB]:
    if len(pixels) <= limit:
        return pixels
    step = max(1, math.ceil(len(pixels) / limit))
    return (pixels[index] for index in range(0, len(pixels), step))


def _bucket(rgb: RGB) -> RGB:
    # 16 levels per channel removes JPEG noise without flattening the palette.
    return tuple(min(255, (channel // 16) * 16 + 8) for channel in rgb)  # type: ignore[return-value]


def extract_seed(pixels: Sequence[RGB]) -> tuple[str, dict[str, object]]:
    samples = list(_sample(pixels))
    if not samples:
        raise ValueError("wallpaper has no pixels")
    buckets = Counter(_bucket(rgb) for rgb in samples)
    total = len(samples)
    scored = []
    for rgb, count in buckets.items():
        red, green, blue = (channel / 255.0 for channel in rgb)
        hue, saturation, value = colorsys.rgb_to_hsv(red, green, blue)
        lightness = (max(red, green, blue) + min(red, green, blue)) / 2.0
        if saturation < 0.06 and 0.08 < lightness < 0.94:
            # Large neutral sky/wall regions should not drown out the actual
            # accent, which is the failure mode this heuristic is designed to
            # avoid.
            continue
        prominence = count / total
        vividness = 0.30 + 0.70 * saturation
        usable_light = 0.65 + 0.35 * (1.0 - abs(lightness - 0.52) / 0.52)
        score = (prominence**0.55) * vividness * usable_light
        scored.append((score, prominence, saturation, rgb))
    if not scored:
        scored = [((count / total) ** 0.55, count / total, 0.0, rgb) for rgb, count in buckets.items()]
    score, prominence, saturation, rgb = max(scored, key=lambda item: (item[0], item[1], item[2], item[3]))
    seed = "#%02x%02x%02x" % rgb
    return seed, {
        "method": "quantized-prominent-chroma-v1",
        "samples": total,
        "buckets": len(buckets),
        "prominence": round(prominence, 6),
        "saturation": round(saturation, 6),
        "score": round(score, 6),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wallpaper", type=Path)
    parser.add_argument("--json", action="store_true", help="print metadata as JSON")
    args = parser.parse_args()
    try:
        seed, metadata = extract_seed(load_pixels(args.wallpaper))
    except (OSError, ValueError, zlib.error, binascii.Error) as error:
        parser.error(str(error))
    if args.json:
        print(json.dumps({"source": str(args.wallpaper), "seed": seed, **metadata}, sort_keys=True))
    else:
        print(seed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
