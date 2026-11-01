#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Test the installed real PAM policy with an ephemeral cloud-container user.

No host credentials, permissive PAM replacement, or real session lock is used.
This is separate from the native greeter presentation/loading smoke test.
"""
import ctypes as c
import ctypes.util
import json
import os
from pathlib import Path
import pwd
import secrets
import shutil
import subprocess
import sys
import tempfile


def require_cloud():
    if os.environ.get('OWODE_CLOUD_PAM_TEST') != '1' or not Path('/.dockerenv').is_file():
        raise SystemExit('Cloud Docker container only; set OWODE_CLOUD_PAM_TEST=1 explicitly')


def authenticate(user, password):
    class Message(c.Structure):
        _fields_ = [('style', c.c_int), ('text', c.c_char_p)]

    class Response(c.Structure):
        _fields_ = [('text', c.c_void_p), ('code', c.c_int)]

    callback_type = c.CFUNCTYPE(c.c_int, c.c_int, c.POINTER(c.POINTER(Message)),
                              c.POINTER(c.POINTER(Response)), c.c_void_p)

    class Conversation(c.Structure):
        _fields_ = [('callback', callback_type), ('data', c.c_void_p)]

    libc = c.CDLL(ctypes.util.find_library('c'))
    libc.calloc.argtypes = [c.c_size_t, c.c_size_t]
    libc.calloc.restype = c.c_void_p
    libc.strdup.argtypes = [c.c_char_p]
    libc.strdup.restype = c.c_void_p

    @callback_type
    def respond(count, messages, responses, unused):
        if count <= 0 or count > 32:
            return 19  # PAM_CONV_ERR
        values = c.cast(libc.calloc(count, c.sizeof(Response)), c.POINTER(Response))
        if not values:
            return 5  # PAM_BUF_ERR
        for index in range(count):
            style = messages[index].contents.style
            if style == 1:  # PAM_PROMPT_ECHO_OFF
                values[index].text = libc.strdup(password.encode())
            elif style == 2:  # PAM_PROMPT_ECHO_ON
                values[index].text = libc.strdup(user.encode())
            # PAM_ERROR_MSG and PAM_TEXT_INFO carry no response and are not logged.
        responses[0] = values
        return 0

    pam = c.CDLL(ctypes.util.find_library('pam'))
    pam.pam_start.argtypes = [c.c_char_p, c.c_char_p, c.POINTER(Conversation),
                             c.POINTER(c.c_void_p)]
    pam.pam_authenticate.argtypes = [c.c_void_p, c.c_int]
    pam.pam_end.argtypes = [c.c_void_p, c.c_int]
    handle = c.c_void_p()
    conversation = Conversation(respond, None)
    result = pam.pam_start(b'kde', user.encode(), c.byref(conversation), c.byref(handle))
    if result == 0:
        result = pam.pam_authenticate(handle, 0)
    if handle:
        pam.pam_end(handle, result)
    return result


def main():
    require_cloud()
    if len(sys.argv) == 3 and sys.argv[1] == '--child':
        password = sys.stdin.readline().rstrip('\n')
        # Only numeric results leave the process; the synthetic secret is never logged.
        print(json.dumps({'correct': authenticate(sys.argv[2], password),
                          'incorrect': authenticate(sys.argv[2], password + '-wrong')}))
        return
    if os.geteuid() != 0:
        raise SystemExit('The outer cloud runner must be root to create its disposable account')
    policy_only = sys.argv[1:] == ['--policy-only']
    if sys.argv[1:] and not policy_only:
        raise SystemExit('Usage: cloud-locker-pam.py [--policy-only]')
    restricted_helper = any(line.split() == ['NoNewPrivs:', '1']
                            for line in Path('/proc/self/status').read_text().splitlines())
    if restricted_helper and not policy_only:
        raise SystemExit('Container forbids setuid unix_chkpwd (NoNewPrivs=1). '
                         'Use --policy-only for a root-client policy check; '
                         'unprivileged authentication remains unverified here.')
    for service in ('kde', 'kde-fingerprint', 'kde-smartcard'):
        if not any((Path(base) / service).is_file() for base in ('/etc/pam.d', '/usr/lib/pam.d')):
            raise SystemExit(f'Missing installed policy: {service}')
    user = 'owode-pam-' + secrets.token_hex(4)
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

        # CircleCI checks out below /root, which the test user cannot traverse.
        with tempfile.TemporaryDirectory(prefix='owode-pam-runner-') as directory:
            os.chmod(directory, 0o755)
            child = Path(directory) / 'probe.py'
            shutil.copyfile(__file__, child)
            child.chmod(0o644)
            result = subprocess.run([sys.executable, str(child), '--child', user],
                                    input=password + '\n', text=True, capture_output=True,
                                    preexec_fn=None if policy_only else drop_privileges,
                                    timeout=40, check=True)
        codes = json.loads(result.stdout)
        if codes['correct'] != 0 or codes['incorrect'] == 0:
            raise SystemExit(f'PAM authentication contract failed: {codes}')
        output = Path('artifacts/locker-pam')
        output.mkdir(parents=True, exist_ok=True)
        (output / 'summary.json').write_text(json.dumps({
            'service': 'kde', 'unprivilegedClient': not policy_only,
            'correctPasswordAccepted': True, 'incorrectPasswordRejected': True,
            'permissivePolicyInstalled': False, 'realSessionLocked': False,
            'restrictedSetuidHelper': restricted_helper,
            'scope': ('Root-client policy check only; unprivileged helper NOT verified'
                      if policy_only else
                      'Real distribution PAM password stack, independent of greeter UI'),
        }, indent=2) + '\n')
        print('Real PAM: correct password accepted, incorrect password rejected; client=' +
              ('root (policy only, NOT an unlock acceptance test)' if policy_only else
               'unprivileged user'))
    finally:
        subprocess.run(['userdel', user], check=True, stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
