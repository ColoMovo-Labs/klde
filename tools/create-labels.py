#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Plan missing KLDE labels; --apply creates them without replacing existing labels."""

import argparse
import json
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    repository = "ColoMovo-Labs/klde"
    desired = json.loads(
        (Path(__file__).resolve().parents[1] / ".github/labels.json").read_text()
    )
    result = subprocess.run(
        ["gh", "label", "list", "--repo", repository, "--limit", "1000", "--json", "name"],
        check=True, capture_output=True, text=True,
    )
    existing = {label["name"].casefold() for label in json.loads(result.stdout)}
    for label in desired:
        if label["name"].casefold() in existing:
            continue
        print(f"{'Create' if args.apply else 'Would create'}: {label['name']}")
        if args.apply:
            subprocess.run(
                ["gh", "label", "create", label["name"], "--repo", repository,
                 "--color", label["color"], "--description", label["description"]],
                check=True,
            )


if __name__ == "__main__":
    main()
