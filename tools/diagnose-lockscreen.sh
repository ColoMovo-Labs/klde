#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Read-only metadata. Never prompts for, reads or tests a login password.
set -eu
printf 'owoDE locker installation\n'
if command -v rpm >/dev/null; then
    rpm -q klde-shell-preview owode-session kscreenlocker plasma-workspace-libs pam || true
fi
missing=0
for service in kde kde-fingerprint kde-smartcard; do
    policy=
    for base in /etc/pam.d /usr/lib/pam.d; do
        if [[ -r "$base/$service" ]]; then
            policy="$base/$service"
            break
        fi
    done
    if [[ -z "$policy" ]]; then
        printf 'MISSING: %s PAM policy; install the matching owode-session RPM.\n' "$service"
        missing=1
    else
        printf 'PAM %s: %s\n' "$service" "$policy"
        if command -v rpm >/dev/null; then rpm -qf "$policy" || true; fi
    fi
done
if [[ ! -r /etc/pam.d/password-auth ]]; then
    printf 'MISSING: Fedora password-auth stack.\n'
    missing=1
fi
if [[ -x /usr/sbin/unix_chkpwd ]]; then
    stat -c 'PAM password helper: %a %U:%G' /usr/sbin/unix_chkpwd
fi
if command -v authselect >/dev/null; then authselect check || true; fi
printf 'No passwords checked; no settings changed.\n'
exit "$missing"
