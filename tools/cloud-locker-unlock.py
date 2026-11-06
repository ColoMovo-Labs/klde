#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Exercise the installed KDE Greeter and real PAM with a disposable user.

Uses a private Xvfb display and --testing. Never locks a session, reads a host
password, changes authentication policy or passes a password in process args.
"""
import json
import os
from pathlib import Path
import pwd
import secrets
import shutil
import signal
import subprocess
import sys
import tempfile
import time


def child(prefix, output):
    password = sys.stdin.readline().rstrip('\n')
    output = Path(output)
    env = dict(os.environ, QT_QPA_PLATFORM='xcb', QT_QUICK_BACKEND='software',
               QT_LOGGING_RULES='kscreenlocker_greet.debug=true',
               QT_FORCE_STDERR_LOGGING='1',
               XDG_RUNTIME_DIR=str(output), XDG_CONFIG_HOME=str(output / 'config'),
               XDG_CACHE_HOME=str(output / 'cache'),
               XDG_DATA_HOME=str(output / 'data'))
    with (output / 'greeter.log').open('w') as log:
        greeter = subprocess.Popen([
            '/usr/libexec/kscreenlocker_greet', '--testing', '--immediateLock',
            '--shell', str(Path(prefix) / 'share/plasma/shells/org.owode.shell')],
            env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            time.sleep(4)
            if greeter.poll() is not None:
                raise RuntimeError('Greeter exited before authentication')
            windows = subprocess.check_output([
                'xdotool', 'search', '--onlyvisible', '--pid', str(greeter.pid)],
                text=True, env=env).splitlines()
            if not windows:
                raise RuntimeError('Greeter has no visible test window')
            subprocess.run(['xdotool', 'windowsize', windows[0], '1440', '900'], check=True, env=env)
            subprocess.run(['xdotool', 'windowfocus', '--sync', windows[0]], check=True, env=env)
            time.sleep(0.2)
            subprocess.run(['magick', 'import', '-window', 'root', str(output / 'greeter.png')],
                           check=True, env=env)

            def submit(value):
                subprocess.run(['xdotool', 'key', 'ctrl+a'], check=True, env=env)
                subprocess.run(['xdotool', 'type', '--clearmodifiers', '--file', '-'],
                               input=value, text=True, check=True, env=env)
                subprocess.run(['xdotool', 'key', 'Return'], check=True, env=env)

            submit(password + '-wrong')
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                if 'Failure from interactive authenticator kde' in (output / 'greeter.log').read_text(errors='replace'):
                    break
                if greeter.poll() is not None:
                    raise RuntimeError('Greeter exited after an incorrect password')
                time.sleep(0.1)
            else:
                raise RuntimeError('System authenticator did not confirm rejection of the wrong password')
            if greeter.poll() is not None:
                raise RuntimeError('Greeter exited after an incorrect password')
            subprocess.run(['magick', 'import', '-window', 'root', str(output / 'rejected.png')],
                           check=True, env=env)
            submit(password)
            if greeter.wait(timeout=25) != 0:
                raise RuntimeError('Correct password did not complete authentication')
        finally:
            if greeter.poll() is None:
                greeter.terminate()
                greeter.wait(timeout=5)
    text = (output / 'greeter.log').read_text(errors='replace')
    if 'Unlocked' not in text:
        raise RuntimeError('Greeter did not confirm authenticated exit')
    for error in ('Received prompt response, but no pending prompt was found!',
                  'custom locker appearance failed', 'ReferenceError:', 'TypeError:',
                  'is not installed', 'is not a type', 'Cannot assign to'):
        if error in text:
            raise RuntimeError('Greeter regression: ' + error)
    print(json.dumps({'correctPasswordUnlocked': True, 'incorrectPasswordKeptLocked': True,
                      'unprivilegedClient': True, 'greeterTestingMode': True,
                      'realSessionLocked': False, 'display': 'private Xvfb',
                      'scope': 'Installed QML -> KScreenLocker authenticator -> real PAM'}))


def main():
    if sys.argv[1:2] == ['--child']:
        child(sys.argv[2], sys.argv[3])
        return
    if (os.environ.get('OWODE_CLOUD_UNLOCK_TEST') != '1'
            or not Path('/.dockerenv').is_file() or os.geteuid() != 0):
        raise SystemExit('Isolated cloud container only; set OWODE_CLOUD_UNLOCK_TEST=1')
    if len(sys.argv) != 2:
        raise SystemExit('Usage: cloud-locker-unlock.py INSTALL_PREFIX')
    prefix = Path(sys.argv[1]).resolve()
    if not (prefix / 'share/plasma/shells/org.owode.shell/contents/lockscreen/Greeter.qml').is_file():
        raise SystemExit('Install the matching shell into the private prefix first')
    if any(line.split() == ['NoNewPrivs:', '1']
           for line in Path('/proc/self/status').read_text().splitlines()):
        raise SystemExit('Container prevents the unprivileged PAM helper; cannot verify unlock')
    user = 'owode-unlock-' + secrets.token_hex(4)
    password = secrets.token_urlsafe(24)
    subprocess.run(['useradd', '--no-create-home', '--shell', '/bin/sh', user], check=True)
    try:
        subprocess.run(['chpasswd'], input=f'{user}:{password}\n', text=True,
                       check=True, stdout=subprocess.DEVNULL)
        account = pwd.getpwnam(user)

        def drop_privileges():
            os.setgroups([])
            os.setgid(account.pw_gid)
            os.setuid(account.pw_uid)

        with tempfile.TemporaryDirectory(prefix='owode-unlock-') as directory:
            directory = Path(directory)
            directory.chmod(0o755)
            runner = directory / 'probe.py'
            shutil.copyfile(__file__, runner)
            runner.chmod(0o644)
            runtime = directory / 'runtime'
            runtime.mkdir(mode=0o700)
            os.chown(runtime, account.pw_uid, account.pw_gid)
            process = subprocess.Popen([
                'xvfb-run', '-a', '-s', '-screen 0 1440x900x24 -nolisten tcp',
                'dbus-run-session', '--', sys.executable, str(runner), '--child',
                str(prefix), str(runtime)], preexec_fn=drop_privileges,
                cwd=directory, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE, text=True, start_new_session=True)
            try:
                stdout, stderr = process.communicate(password + '\n', timeout=60)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGTERM)
                process.communicate(timeout=5)
                raise SystemExit('Greeter authentication test timed out')
            artifacts = Path('artifacts/locker-unlock')
            artifacts.mkdir(parents=True, exist_ok=True)
            log = runtime / 'greeter.log'
            if log.exists():
                shutil.copyfile(log, artifacts / 'greeter.log')
            for screenshot in runtime.glob('*.png'):
                shutil.copyfile(screenshot, artifacts / screenshot.name)
            if process.returncode:
                detail = (stdout + stderr).replace(password, '[redacted]')
                raise SystemExit(f'Greeter unlock test failed ({process.returncode}): ' + detail)
            summary = json.loads(stdout)
            (artifacts / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
            print('Greeter + real PAM: wrong password rejected, correct password unlocked (unprivileged Xvfb test)')
    finally:
        subprocess.run(['userdel', user], check=True, stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
