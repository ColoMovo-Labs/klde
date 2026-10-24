#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Fetch audited source for the optional calculator port; never run at runtime."""
import hashlib
from pathlib import Path
import sys
import tarfile
import urllib.request

REVISION = "c2fdb5c80049ce6ffb02571e4bbc64fca1c2366e"
SHA256 = "9560a14d302e797ac0606ea79ced47c8da3bf25de1e00979b9a2b070093bc417"


def main():
    target = Path(sys.argv[1]).resolve()
    if target.exists():
        raise SystemExit("Choose a fresh upstream directory; existing source is never overwritten")
    target.parent.mkdir(parents=True, exist_ok=True)
    archive = target.parent / "lingmo-calculator-source.tar.gz"
    url = f"https://codeload.github.com/LingmoOS/lingmo-calculator/tar.gz/{REVISION}"
    with urllib.request.urlopen(url, timeout=60) as response:
        content = response.read(8 * 1024 * 1024 + 1)
    if len(content) > 8 * 1024 * 1024 or hashlib.sha256(content).hexdigest() != SHA256:
        raise SystemExit("Upstream source size or SHA256 mismatch")
    archive.write_bytes(content)
    target.mkdir()
    with tarfile.open(archive) as source:
        prefix = f"lingmo-calculator-{REVISION}/"
        for member in source.getmembers():
            if member.isdir() and member.name.rstrip("/") == prefix.rstrip("/"):
                continue
            if not member.name.startswith(prefix):
                raise SystemExit("Unexpected archive prefix")
            member.name = member.name[len(prefix):]
            if member.name:
                source.extract(member, target, filter="data")
    # Two inherited allocator mismatches in HMath: formatFixed uses malloc.
    # Preserve upstream headers and keep this narrow patch fully reproducible.
    hmath = target / "engine/hmath.cpp"
    text = hmath.read_text()
    if text.count("delete[] str;") != 2:
        raise SystemExit("Allocator fix no longer matches the audited source")
    hmath.write_text(text.replace("delete[] str;", "free( str );"))
    (target / ".owode-upstream-commit").write_text(REVISION + "\n")
    print(f"Verified Lingmo Calculator {REVISION}; applied two allocator corrections")


if __name__ == "__main__":
    main()
