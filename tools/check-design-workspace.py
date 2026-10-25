#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check the maintained visual module manifest and UI-form subset before CI builds."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
module = root / "design/Owo/Visuals"
files = {p.name for p in module.glob("*.qml")}
manifest = set(re.findall(r"\b[\w]+(?:\.ui)?\.qml\b", (module / "CMakeLists.txt").read_text()))
assert files == manifest, ("CMake visual file registration mismatch", files ^ manifest)
registered = {line.split()[-1] for line in (module / "qmldir").read_text().splitlines()[1:]}
assert files == registered, ("Designer import registration mismatch", files ^ registered)
for form in (root / "design").rglob("*.ui.qml"):
    text = form.read_text()
    assert not re.search(r"\bon[A-Z]\w*\s*:", text), (form, "Signal handler belongs in .qml")
    assert not re.search(r"\b(?:function|Behavior|Binding|Canvas|ShaderEffect|Timer|Transform)\b", text), (form, "Unsupported UI form construct")
    assert "KLDE.Backends" not in text, (form, "Native/mock C++ backend in designer")
    if form.parent == module:
        assert "import Owo.Visuals" in text, (form, "Standalone QDS editing needs an explicit visual-module import")
print(f"Visual workspace: {len(files)} registered shared components, UI-form subset checked")
