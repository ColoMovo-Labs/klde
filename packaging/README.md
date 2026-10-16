# Packaging scope

Phase 0 checks `cmake --install` into a staging directory and archives that tree.
The archive contains a binary, a preview desktop entry and project license texts.
It is a CI artifact, not a standalone redistributable bundle or `.deb` package.
It requires compatible distribution Qt libraries and QML runtime modules.

No login-session entry, systemd unit, polkit helper or host-desktop replacement
is installed. Debian packaging, dependency generation, source delivery, license
inventory, upgrade/remove tests and reproducibility are Phase 7 work. Do not
install artifacts into a production desktop as if they were stable packages.
