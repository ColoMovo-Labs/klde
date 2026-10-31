#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Cloud-only Fedora GDM/logind/virtual-DRM acceptance; never a local launcher."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shlex
import shutil
import signal
import socket
import subprocess
import tempfile
import time


FEDORA_KEY = "36F612DCF27F7D1A48A835E4DBFCF71C6D9F90A6"
IMAGE = "Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2"
CHECKSUM = "Fedora-Cloud-44-1.7-x86_64-CHECKSUM"
BASE_URL = "https://dl.fedoraproject.org/pub/fedora/linux/releases/44/Cloud/x86_64/images/"
REPO = Path(__file__).resolve().parents[1]


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def fetch(url, path):
    run(["curl", "--fail", "--location", "--retry", "3", "--max-time", "600",
         "--output", str(path), url])


def wait_for(description, action, seconds):
    deadline = time.monotonic() + seconds
    print("Waiting for " + description, flush=True)
    while time.monotonic() < deadline:
        if action():
            return
        time.sleep(3)
    raise TimeoutError(description)


def qmp(path, command, arguments=None):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(15)
        connection.connect(str(path))
        with connection.makefile("rwb") as stream:
            json.loads(stream.readline())  # Greeting, before capabilities.
            for request in [{"execute": "qmp_capabilities"},
                            {"execute": command, "arguments": arguments or {}}]:
                stream.write((json.dumps(request) + "\n").encode())
                stream.flush()
                while True:
                    reply = json.loads(stream.readline())
                    if "event" not in reply:
                        break
                if "error" in reply:
                    raise RuntimeError(reply["error"])
            return reply["return"]


def main():
    # This script downloads/boots an OS and changes ONLY its disposable guest.
    # CIRCLECI alone can be inherited in local shells; require the dedicated job.
    if (os.environ.get("CIRCLECI") != "true"
            or os.environ.get("CIRCLE_JOB") != "fedora-login-vm"
            or os.environ.get("OWODE_VM_CLOUD_ONLY") != "1"):
        raise SystemExit("Only the dedicated CircleCI fedora-login-vm job may run this test.")
    def interrupted(_signal, _frame):
        raise SystemExit("Cloud VM test interrupted; cleaning up its owned guest.")
    signal.signal(signal.SIGTERM, interrupted)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--packages", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO,
                                       text=True).strip()
    rpms = sorted(args.packages.resolve().glob("*.rpm"))
    assert len(rpms) == 2, "Exactly the matching preview and optional session RPMs are required"
    receipts = list(args.packages.glob("*.source-commit.txt"))
    assert len(receipts) == 1 and receipts[0].read_text().strip() == revision
    run(["sha256sum", "--check", "SHA256SUMS"], cwd=args.packages.resolve(),
        stdout=(output / "package-checksums.txt").open("w"))
    (output / "source-commit.txt").write_text(revision + "\n")
    # No disks, NoCloud seed, private keys, sockets or SSH configs are artifacts.
    with tempfile.TemporaryDirectory(prefix="owode-cloud-vm-") as scratch:
        private = Path(scratch)
        keyring = private / "gnupg"
        keyring.mkdir(mode=0o700)
        fetch("https://fedoraproject.org/fedora.gpg", private / "fedora.gpg")
        run(["gpg", "--homedir", str(keyring), "--batch", "--import",
             str(private / "fedora.gpg")], stdout=subprocess.DEVNULL)
        with (private / "fedora44.gpg").open("wb") as stream:
            run(["gpg", "--homedir", str(keyring), "--batch", "--export", FEDORA_KEY],
                stdout=stream)
        assert (private / "fedora44.gpg").stat().st_size > 0
        fetch(BASE_URL + CHECKSUM, private / CHECKSUM)
        with (output / "image-signature.txt").open("w") as stream:
            run(["gpgv", "--keyring", str(private / "fedora44.gpg"),
                 str(private / CHECKSUM)], stdout=stream, stderr=stream)
        matched = re.search(r"^SHA256 \(" + re.escape(IMAGE) + r"\) = ([0-9a-f]{64})$",
                            (private / CHECKSUM).read_text(), re.MULTILINE)
        assert matched, "Signed Fedora checksum must name this exact image"
        fetch(BASE_URL + IMAGE, private / IMAGE)
        with (private / IMAGE).open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        assert digest == matched[1], "Fedora image checksum mismatch"
        (output / "image-provenance.json").write_text(json.dumps({
            "url": BASE_URL + IMAGE, "sha256": digest, "signingFingerprint": FEDORA_KEY,
            "signatureVerified": True, "checksumVerified": True}, indent=2) + "\n")
        info = json.loads(subprocess.check_output(
            ["qemu-img", "info", "--output=json", str(private / IMAGE)]))
        assert info["format"] == "qcow2" and not info.get("backing-filename")
        run(["qemu-img", "create", "-f", "qcow2", "-F", "qcow2", "-b",
             str(private / IMAGE), str(private / "guest.qcow2"), "28G"])
        run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(private / "key")])
        public_key = (private / "key.pub").read_text().strip()
        marker = secrets.token_hex(16)
        # Fixed-purpose guest account. SSH password login is disabled; no owner
        # credentials, mounts, devices or host session environment are passed.
        (private / "user-data").write_text(
            "#cloud-config\npreserve_hostname: false\nhostname: owode-ci-vm\nssh_pwauth: false\n"
            "users:\n  - name: owodeci\n    groups: [wheel]\n    shell: /bin/bash\n"
            "    lock_passwd: true\n    sudo: ALL=(ALL) NOPASSWD:ALL\n"
            "    ssh_authorized_keys:\n      - " + public_key + "\n"
            "write_files:\n  - path: /etc/owode-ci-vm\n    permissions: '0600'\n"
            "    content: " + marker + "\n")
        (private / "meta-data").write_text("instance-id: owode-" + marker + "\nlocal-hostname: owode-ci-vm\n")
        run(["cloud-localds", str(private / "seed.iso"), str(private / "user-data"),
             str(private / "meta-data")])
        # Let QEMU select an unused loopback port (no listener is exposed externally).
        qmp_socket = private / "qmp.sock"
        accelerated = os.access("/dev/kvm", os.R_OK | os.W_OK)
        accelerator = "kvm" if accelerated else "tcg,thread=multi"
        (output / "virtualization.json").write_text(json.dumps({
            "accelerator": accelerator, "virtualGPU": "virtio-vga (no 3D passthrough)",
            "physicalGPUAcceptance": False, "passwordLoginAcceptance": False,
            "secureLockAcceptance": False, "hostSessionModified": False}, indent=2) + "\n")
        command = ["qemu-system-x86_64", "-accel", accelerator, "-cpu", "host" if accelerated else "max",
                   "-m", "4096", "-smp", "2",
                   "-drive", f"file={private / 'guest.qcow2'},if=virtio,format=qcow2",
                   "-drive", f"file={private / 'seed.iso'},media=cdrom,readonly=on",
                   "-device", "virtio-vga", "-display", "none", "-nic",
                   "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:0-:22",
                   "-qmp", f"unix:{qmp_socket},server=on,wait=off", "-serial",
                   f"file:{output / 'serial.log'}", "-no-reboot"]
        with (output / "qemu.log").open("w") as log:
            process = subprocess.Popen(command, stdout=log, stderr=log)
            ssh = None
            try:
                wait_for("QMP", lambda: qmp_socket.exists() or process.poll() is not None, 30)
                assert process.poll() is None, "QEMU exited; inspect qemu.log"
                networks = qmp(qmp_socket, "human-monitor-command", {"command-line": "info usernet"})
                # QEMU HMP table: TCP[HOST_FORWARD] fd 127.0.0.1 port 10.0.2.15 22 ...
                forwarded = re.search(r"TCP\[HOST_FORWARD\]\s+\d+\s+127\.0\.0\.1\s+(\d+)", networks)
                assert forwarded, networks
                ssh = ["ssh", "-i", str(private / "key"), "-p", forwarded[1], "-o",
                       "BatchMode=yes", "-o", "ConnectTimeout=5", "-o", "StrictHostKeyChecking=accept-new",
                       "-o", f"UserKnownHostsFile={private / 'known_hosts'}", "owodeci@127.0.0.1"]
                wait_for("Fedora SSH/cloud-init", lambda: subprocess.run(
                    ssh + ["test -e /var/lib/cloud/instance/boot-finished"],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0, 600)
                # Tar transport uses only tracked test files and matching RPMs.
                payload = private / "payload"
                payload.mkdir()
                for path in rpms + [REPO / "tests/session/vm-guest.sh",
                                    REPO / "tests/session/vm-state.js",
                                    REPO / "tools/wait-native-buffers.py"]:
                    shutil.copy2(path, payload / path.name)
                with (private / "payload.tar").open("wb") as stream:
                    run(["tar", "-C", str(payload), "-cf", "-", "."], stdout=stream)
                with (private / "payload.tar").open("rb") as stream:
                    run(ssh + ["mkdir -p /tmp/owode-vm-payload && tar -C /tmp/owode-vm-payload -xf -"], stdin=stream)
                run(ssh + ["sudo bash /tmp/owode-vm-payload/vm-guest.sh setup " + shlex.quote(marker)], timeout=1500)
                # Framebuffer capture is independent of the shell/QML capture APIs.
                qmp(qmp_socket, "screendump", {"filename": str(output / "gdm-owode.png"), "format": "png"})
                run(ssh + ["sudo bash /tmp/owode-vm-payload/vm-guest.sh logout " + shlex.quote(marker)], timeout=180)
                qmp(qmp_socket, "screendump", {"filename": str(output / "returned-greeter.png"), "format": "png"})
                (output / "acceptance.json").write_text(json.dumps({
                    "sourceCommit": revision, "status": "passed", "gdmAutologin": True,
                    "logindWaylandSession": True, "virtualDRM": True, "returnToGreeter": True,
                    "passwordAuthentication": "not tested", "secureLock": "not tested",
                    "physicalGPU": "not tested"}, indent=2) + "\n")
            finally:
                try:
                    if ssh:
                        with (output / "guest-evidence.tar.gz").open("wb") as stream:
                            subprocess.run(ssh + ["sudo tar -C /var/tmp/owode-vm-evidence -czf - ."],
                                           stdout=stream, timeout=60)
                except (OSError, subprocess.TimeoutExpired) as error:
                    print("Guest evidence collection incomplete: " + type(error).__name__, flush=True)
                finally:
                    try:
                        qmp(qmp_socket, "quit")
                    except (OSError, ValueError, RuntimeError):
                        pass
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        process.terminate()
                        try:
                            process.wait(timeout=10)
                        except subprocess.TimeoutExpired:
                            process.kill()
                            process.wait(timeout=10)


if __name__ == "__main__":
    main()
