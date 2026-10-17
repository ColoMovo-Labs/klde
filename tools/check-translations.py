#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Cloud validation of embedded ID catalogs and sparse voice overrides."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate translation ID: {key}")
        if not isinstance(value, str) or not value:
            raise ValueError(f"Translation must be nonempty text: {key}")
        result[key] = value
    return result


def read(path):
    return json.loads(path.read_text(), object_pairs_hook=unique_object)


def placeholders(value):
    return sorted(re.findall(r"%[1-9][0-9]*", value))


def main():
    english = read(ROOT / "translations/en.json")
    chinese = read(ROOT / "translations/zh_CN.json")
    if english.keys() != chinese.keys():
        raise ValueError("English and Simplified Chinese base IDs differ")
    for key, value in english.items():
        if not re.fullmatch(r"[a-z][a-z0-9]*(?:[.-][a-z0-9]+)+", key):
            raise ValueError(f"Malformed stable ID: {key}")
        if placeholders(value) != placeholders(chinese[key]):
            raise ValueError(f"Placeholder mismatch: {key}")
    for locale in ("en", "zh_CN"):
        cute = read(ROOT / f"translations/voices/cute/{locale}.json")
        for key, value in cute.items():
            if key not in english:
                raise ValueError(f"Cute override has no Standard base: {key}")
            if not key.startswith(("shell.", "friendly.", "ambient.")):
                raise ValueError(f"Voice override in tone-locked namespace: {key}")
            if placeholders(value) != placeholders(english[key]):
                raise ValueError(f"Cute placeholder mismatch: {key}")
    for path in (ROOT / "qml").rglob("*.qml"):
        source = path.read_text()
        if re.search(r"\bqsTr\s*\(", source):
            raise ValueError(f"Use stable I18n.t IDs in presentation: {path}")
        for key in re.findall(r'I18n\.t\("([a-z0-9.-]+)"\)', source):
            if key not in english:
                raise ValueError(f"Missing required UI ID {key} in {path}")
    for relative in ("src/mock/scenarios.json", "src/status/modules.json"):
        data = json.loads((ROOT / relative).read_text())
        entries = data["scenarios"] if isinstance(data, dict) else data
        for item in entries:
            if item["titleId"] not in english:
                raise ValueError(f"Missing fixture/module title: {item['titleId']}")
    for context in ("battery", "temperature", "session"):
        for part in ("title", "body"):
            if f"critical.notification.{context}.{part}" not in english:
                raise ValueError("Critical notification vocabulary is incomplete")
    # Existing C++ mock contracts retain a source-text bridge until their data models
    # expose message IDs. Ensure every legacy tr() source has a bilingual base.
    sources = set(english.values())
    for path in (ROOT / "src").rglob("*.cpp"):
        if re.search(r"\b(?:reject|requestRejected|showNotice|actionReported)\(\s*QStringLiteral\(", path.read_text()):
            raise ValueError(f"Route owned user-facing backend notices through cataloged tr(): {path}")
        for value in re.findall(r'\btr\("((?:\\.|[^"\\])*)"\)', path.read_text()):
            if json.loads('"' + value + '"') not in sources:
                raise ValueError(f"Missing base for C++ message in {path}: {value}")
    for status in ("mock", "loading", "ready", "unavailable", "rate-limited", "quota-exhausted"):
        if "weather.status." + status not in english:
            raise ValueError(f"Missing dynamic weather status: {status}")
    print(f"Validated {len(english)} bilingual IDs and sparse tone-safe voice catalogs")


if __name__ == "__main__":
    main()
