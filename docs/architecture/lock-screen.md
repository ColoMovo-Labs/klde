# Lock-screen architecture boundary

The Visual Lab's `LockScreenSurface` remains a mock visual state machine. It has
no credentials, PAM calls, privileged helper or session-lock authority. A native
session uses distribution KWin/KScreenLocker, with the independent presentation
package below; it never treats the Visual Lab window as a security boundary.

## Native KScreenLocker package

### Fedora authentication policy

Fedora's KScreenLocker 6.7.5 greeter uses the PAM service `kde`. The distribution
ships `kde`, `kde-fingerprint` and `kde-smartcard` policies inside the full
plasma-workspace package; installing kscreenlocker and plasma-workspace-libs
alone does not install them. With none of these files on the reported host,
Linux-PAM falls back to `other`, which explicitly uses pam_deny. Correct
passwords are therefore rejected before a working password policy is reached.

The Fedora owode-session RPM supplies small, original **vendor defaults** in
`/usr/lib/pam.d`. The password service delegates to authselect's `password-auth`
stack; no generated authselect file or global login/sudo policy is rewritten.
An administrator or Plasma-supplied `/etc/pam.d/kde` policy takes precedence,
avoiding a file ownership conflict with Plasma. Optional fingerprint/smartcard
defaults explicitly deny until separately configured in `/etc/pam.d`; they do
not inherit an accidental fallback or pretend biometric support is available.
The login launcher checks for these required files before starting a session.

After installing the matching Fedora RPM pair, the cloud-only command
`OWODE_CLOUD_PAM_TEST=1 python3 tools/cloud-locker-pam.py` creates a disposable
container user and tests the real PAM stack after dropping root privileges.
It requires a correct synthetic password to succeed and a wrong password to
fail, then deletes the account. It never changes PAM to permit authentication,
uses no host password, and locks no session. This test supplements the native
greeter loading gate; actual host greeter-to-PAM unlocking still needs owner
acceptance. Neither screenshot success nor PAM-library success alone proves
the complete lock/unlock lifecycle.

`packaging/lockscreen/org.owode.shell` is a Plasma/Shell KPackage with lockscreen
API version 2, installed in `share/plasma/shells/org.owode.shell`. It contains
an original wallpaper/clock wrapper and three attributed GPL-2.0-or-later
presentation files from KScreenLocker 6.7.5. See
[provenance](../../packaging/lockscreen/upstream.json) and
[license details](../legal/third-party.md). Authentication remains in the
distribution greeter, PAM stack and KWin. The wrapper never handles a password,
calls `Qt.quit()` or decides that authentication succeeded.

The reported Fedora 44 failure was a missing
`org.kde.plasma.private.sessions` import in KDE's fallback LockScreen.qml. That
module is supplied by the full plasma-workspace package. Our wrapper omits the
switch-user feature requiring that import. It still uses Kirigami and Plasma
component libraries, plus the Plasma/Shell package structure from
plasma-workspace-libs. It does not require Plasma Shell to run.

The stable `LockScreen.qml` entry point imports only QtQuick and loads the
custom `OwoLockScreen.qml` through a Loader. An appearance load error switches
to `KdeLockScreen.qml`: a system-palette surface containing the same attributed
KDE Greeter, without wallpaper, design tokens or session-switching imports.
This fallback handles custom appearance failures without reaching the broken
upstream fallback on minimal Fedora installations. It does not bypass PAM or
recover missing system Qt/Plasma libraries. The cloud fallback gate deliberately
breaks only the custom QML in a private install prefix, then requires a live
greeter and committed Wayland buffers from the minimal KDE presentation.

`start-owode` exports `PLASMA_DEFAULT_SHELL=org.owode.shell` within its child
process tree. KScreenLocker uses that default when `plasmashellrc` has no
explicit `Shell/ShellPackage` selection. We never rewrite another desktop's
shared `plasmashellrc` or `kscreenlockerrc`, disable password requirements or
export this selection to the shared user systemd manager. An existing explicit
ShellPackage takes precedence; report that conflict rather than silently
overwriting a user's Plasma preferences. Existing sessions need a new login
after installing the matching shell/session RPM pair to receive this variable.

Cloud-only validation command (inside an isolated Fedora container):

```sh
OWODE_CLOUD_LOCKER_TEST=1 bash tools/locker-theme-smoke.sh build/fedora artifacts/locker-theme
```

The script installs to a private prefix, starts its own Xvfb, D-Bus and nested
KWin, and runs `kscreenlocker_greet --testing --immediateLock --shell <package>`.
It requires real attached/committed Wayland buffers, a live greeter, no QML
import/fallback errors, and saves a screenshot and logs. It never invokes
`loginctl lock-session` or the host's ScreenSaver service. Testing mode proves
package/import/native-render compatibility; it does **not** prove PAM unlock,
production session-lock security, suspend/resume or hotplug acceptance.

CNB's rootless Docker may enforce `NoNewPrivs: 1`, preventing Fedora's setuid
`unix_chkpwd` helper from reading the shadow database for an ordinary client.
The PAM probe fails explicitly in that environment unless `--policy-only` is
requested. That mode checks correct/incorrect synthetic passwords as a root
client, records `unprivilegedClient: false`, and is **not** unlock acceptance.
CircleCI retains the strict nonprivileged probe. No PAM policy or helper
permissions are weakened to accommodate the cloud executor.

## Presentation contract

The surface consumes:

- wallpaper choice and prepared cached assets;
- Display Clock/time/date models;
- weather/environment summary with explicit mock provenance;
- locale/input display state;
- visual state (`ambient`, `auth`, `error`, `reduced`, `depth`, `fallback`).

It does not decide whether the session is locked. The visual state can be driven
by a future `SessionLockBackend` after the backend confirms the session state.

## Security boundary

The session's existing lock request uses the KWin/KScreenLocker system service.
Authentication remains separate from wallpaper and QML state. On lock failure
or backend disconnect, session lock state remains security-owned; the shell
must not silently downgrade to a fullscreen preview. Compatibility with other
greeter versions requires a new pinned source/API audit and native validation.

LingmoOS and Cutefish lock-screen code is research material only. Their audited
PAM/X11 paths do not establish KLDE Wayland security. See
[`docs/architecture/kwin-adapter.md`](kwin-adapter.md) and
[`docs/reuse/lingmo-cutefish.md`](../reuse/lingmo-cutefish.md).

## Cached wallpaper flow

`original wallpaper -> prepared foreground/background -> cached lock blur ->
LockScreenSurface`.

The cache has generation and validity metadata. The surface selects a prepared
asset or an opaque/normal fallback; it never runs segmentation or a large blur
pipeline in response to a lock event.

## Secret-prompt compatibility and unlock regression

KScreenLocker 6.8's asynchronous PAM worker emits the secret-prompt notification
before storing its pending D-Bus reply. Answering synchronously in the copied
Greeter loses the answer (`Received prompt response, but no pending prompt was
found!`). The attributed Greeter now defers its response with `Qt.callLater` and
ignores prompt-clear notifications. It still passes the field only to the system
authenticator and exits only on its success signal. Original and adapted hashes
are recorded in the provenance manifest.

After installing the matching shell/session packages in an isolated Fedora
container with setuid-helper support, run:

```sh
OWODE_CLOUD_UNLOCK_TEST=1 python3 tools/cloud-locker-unlock.py /usr
```

This creates a disposable ordinary account and a private Xvfb/D-Bus session,
requires an explicit system-authenticator rejection of a wrong password, then
requires successful authenticated greeter exit with the correct password. The
secret is passed through stdin, never command arguments or logs. The account is
removed afterward. This tests the installed theme through real PAM, without
locking a host session; Wayland lock ownership and physical suspend/hotplug still
require target-host acceptance. `bash tools/diagnose-lockscreen.sh` separately
reports installed versions, effective PAM policy paths and helper permissions
without testing a user's password.

## Shared depth landscape and effect preferences

`LockLandscape.qml` is installed beside the native greeter and also used by the
Visual Lab and wallpaper preview. The large Rubik clock is painted between the
original snow wallpaper and a transparent mountain SVG with exactly the same
viewBox, paths and crop. The date is painted above that foreground. Missing
foreground assets fall back to a complete wallpaper and unobscured clock.

The live shell publishes only effective appearance values to
`~/.config/owode/lockscreen.conf`; ordinary previews write nothing. The next
system greeter reads this snapshot for theme, transparency, blur enablement and
quality. Clock opacity is bounded to 0.86–1.0: higher effect tiers allow a little
more translucency; disabling transparency or blur restores solid text. Digits
remain sharp, and no continuous blur/render loop is added. The clock updates on
minute boundaries. Qt render tests check actual mountain/clock overlap while
requiring at least 75% of the clock ink to remain visible at common laptop and
desktop sizes.
