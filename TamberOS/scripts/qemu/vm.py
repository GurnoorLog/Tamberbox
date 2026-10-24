#!/usr/bin/env python3
"""Explicit, file-only AlmaLinux ARM64 VM lifecycle. No device or host installs."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import urllib.request
import uuid
from urllib.parse import urlparse
import importlib.util

_spec = importlib.util.spec_from_file_location("tamber_signature", Path(__file__).with_name("verify_signature.py"))
signature = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(signature)

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / 'build'
LOCK = Path(__file__).with_name('image.lock.json')
TOOLS = ('qemu-system-aarch64', 'qemu-img', 'cloud-localds', 'ssh-keygen')


def digest(path):
    with Path(path).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def load_lock(path=LOCK):
    data = json.loads(path.read_text())
    if (data['architecture'] != 'aarch64' or data['release'] != '10.2'
        or not re.fullmatch(r'[0-9a-f]{64}', data['sha256'])
        or Path(data['filename']).name != data['filename']
        or 'latest' in data['filename']
        or data['url'] != 'https://repo.almalinux.org/almalinux/10/cloud/aarch64/images/' + data['filename']):
        raise ValueError('Invalid immutable AlmaLinux image lock')
    return data


def output_path(name):
    """Reject traversal, symlinked build trees and QEMU comma injection."""
    if not re.fullmatch(r'[A-Za-z0-9_-]+', name):
        raise ValueError('VM name must contain only letters, numbers, underscore or hyphen')
    for p in (BUILD, BUILD / 'qemu', BUILD / 'qemu' / name):
        if p.is_symlink():
            raise ValueError('Symlinked output directory rejected')
    if ',' in str(ROOT):
        raise ValueError('QEMU workspace path cannot contain commas')
    return BUILD / 'qemu' / name


def regular(path):
    p = Path(path)
    if p.is_symlink() or not p.is_file():
        raise ValueError(f'Expected ordinary non-symlink file: {p}')
    return p


def verify_image(path, lock):
    if digest(regular(path)) != lock['sha256']:
        raise ValueError('Image SHA256 mismatch; refusing to use it')


def require_tools(names):
    missing = [n for n in names if not shutil.which(n)]
    if missing:
        raise ValueError('Missing tools: ' + ', '.join(missing))


def fetch(lock):
    cache = output_path('cache')
    cache.mkdir(parents=True, exist_ok=True, mode=0o700)
    target = cache / lock['filename']
    if target.exists() or target.is_symlink():
        verify_image(target, lock)
        return target
    partial = target.with_suffix('.partial')
    owned_partial = False
    try:
        dst = partial.open('xb')
        owned_partial = True
        with dst, urllib.request.urlopen(lock['url'], timeout=60) as src:
            if not src.url.startswith('https://'):
                raise ValueError('Non-HTTPS image redirect refused')
            shutil.copyfileobj(src, dst)
        verify_image(partial, lock)
        partial.rename(target)
        target.chmod(0o400)
    except Exception:
        if owned_partial:
            partial.unlink(missing_ok=True)
        raise
    return target


def cloud_config(public_key, smoke, proxy=None):
    if not re.fullmatch(r'ssh-ed25519 [A-Za-z0-9+/=]+(?: [^\r\n]*)?', public_key.strip()):
        raise ValueError('Expected one Ed25519 public key')
    probe = Path(__file__).with_name('guest-check.sh').read_text()
    data = {'users': [{'name': 'tamber', 'lock_passwd': True,
                      'ssh_authorized_keys': [public_key.strip()],
                      'sudo': ['ALL=(ALL) NOPASSWD:ALL'], 'shell': '/bin/bash'}],
            'disable_root': True, 'ssh_pwauth': False,
            'write_files': [{'path': '/usr/local/bin/tamber-m1-check', 'permissions': '0755',
                             'content': probe},
                            {'path': '/etc/tamber-dev-vm', 'permissions': '0644',
                             'content': 'M1 disposable QEMU guest\n'}]}
    if proxy:
        parsed = urlparse(proxy)
        if parsed.scheme != 'http' or parsed.hostname != '10.0.2.2' or not parsed.port or parsed.username or parsed.password or parsed.path or parsed.query or parsed.fragment:
            raise ValueError('Proxy must be a credential-free http://10.0.2.2:PORT host gateway URL')
        data['write_files'].append({'path': '/etc/tamber-dev-proxy', 'permissions': '0644', 'content': proxy + '\n'})
    data['runcmd'] = [['bash', '-c', "{ printf '\\nTAMBER_SSH_HOSTKEY '; cat /etc/ssh/ssh_host_ed25519_key.pub; } > /dev/ttyAMA0"]]
    if smoke:
        data['runcmd'].append(['bash', '-c', '/usr/local/bin/tamber-m1-check > /dev/ttyAMA0 2>&1'])
        data['power_state'] = {'mode': 'poweroff', 'timeout': 60, 'condition': True}
    # JSON is a YAML subset; avoids templating/untrusted YAML injection.
    return '#cloud-config\n' + json.dumps(data, indent=2) + '\n'


def prepare(args, lock):
    dest = output_path(args.name)
    if dest.exists():
        raise ValueError('VM directory exists; choose a new name (never overwritten)')
    signature.verify_lock(lock)
    image = output_path('cache') / lock['filename']
    verify_image(image, lock)
    code, variables = regular(args.code), regular(args.vars)
    require_tools(TOOLS)
    # Reject externally referenced or incorrectly formatted downloaded qcow2 files.
    info = json.loads(subprocess.check_output(['qemu-img', 'info', '--output=json', str(image)]))
    if info['format'] != 'qcow2' or info.get('backing-filename') or info.get('data-file'):
        raise ValueError('Expected standalone qcow2 image')
    dest.mkdir(parents=True, mode=0o700)
    shutil.copyfile(code, dest / 'code.fd')
    shutil.copyfile(variables, dest / 'vars.fd')
    subprocess.run(['ssh-keygen', '-q', '-t', 'ed25519', '-N', '', '-C', 'tamber-dev',
                    '-f', str(dest / 'id_ed25519')], check=True)
    (dest / 'user-data').write_text(cloud_config((dest / 'id_ed25519.pub').read_text(), args.smoke, args.proxy))
    (dest / 'meta-data').write_text(json.dumps({'instance-id': str(uuid.uuid4()), 'local-hostname': 'tamber-dev'}))
    subprocess.run(['cloud-localds', str(dest / 'seed.iso'), str(dest / 'user-data'), str(dest / 'meta-data')], check=True)
    subprocess.run(['qemu-img', 'create', '-f', 'qcow2', '-F', 'qcow2', '-b', str(image),
                    str(dest / 'disk.qcow2'), '20G'], check=True)
    manifest = {'image': lock, 'firmware_code_sha256': digest(dest / 'code.fd'),
                'firmware_vars_initial_sha256': digest(dest / 'vars.fd'), 'smoke': args.smoke,
                'tools': {t: subprocess.check_output([t, '--version'], stderr=subprocess.STDOUT,
                          text=True).splitlines()[0] for t in ('qemu-system-aarch64', 'qemu-img')},
                'seed_sha256': digest(dest / 'seed.iso'), 'guest_proxy': args.proxy}
    (dest / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Prepared {dest}. Private SSH key stays here. No VM started.')


def command(dest, network=False, ssh_port=None):
    if ssh_port is not None and (not network or not 1024 <= ssh_port <= 65535):
        raise ValueError('SSH requires --network and an unprivileged port (1024..65535)')
    net = 'user,id=net0,restrict=' + ('off' if network else 'on')
    if ssh_port:
        net += f',hostfwd=tcp:127.0.0.1:{ssh_port}-:22'
    return ['qemu-system-aarch64', '-machine', 'virt-8.2', '-cpu', 'neoverse-n1', '-accel', 'tcg',
            '-m', '4096', '-smp', '4', '-display', 'none', '-monitor', 'none',
            '-serial', f'file:{dest / "serial.log"}',
            '-drive', f'if=pflash,format=raw,readonly=on,file={dest / "code.fd"}',
            '-drive', f'if=pflash,format=raw,file={dest / "vars.fd"}',
            '-drive', f'if=virtio,format=qcow2,file={dest / "disk.qcow2"}',
            '-drive', f'if=virtio,format=raw,readonly=on,file={dest / "seed.iso"}',
            '-netdev', net, '-device', 'virtio-net-pci,netdev=net0,romfile=', '-no-reboot']


def check_transcript(text):
    required = ('identity', 'network', 'dnf', 'packages')
    lines = text.splitlines()
    return {name: lines.count(f'TAMBER_CHECK {name} PASS') == 1
            and f'TAMBER_CHECK {name} FAIL' not in lines for name in required}


def run(args, lock):
    dest = output_path(args.name)
    cmd = command(dest, args.network, args.ssh_port)
    if args.dry_run:
        print(json.dumps({'command': cmd, 'timeout_seconds': args.timeout}, indent=2))
        return 0
    require_tools(('qemu-system-aarch64', 'qemu-img'))
    for name in ('manifest.json', 'code.fd', 'vars.fd', 'disk.qcow2', 'seed.iso'):
        regular(dest / name)
    manifest = json.loads((dest / 'manifest.json').read_text())
    if manifest['image'] != lock or digest(dest / 'code.fd') != manifest['firmware_code_sha256']:
        raise ValueError('Image lock or firmware differs from prepared manifest')
    if digest(dest / 'seed.iso') != manifest['seed_sha256']:
        raise ValueError('Seed checksum mismatch')
    base = output_path('cache') / lock['filename']
    verify_image(base, lock)
    info = json.loads(subprocess.check_output(['qemu-img', 'info', '-f', 'qcow2', '--output=json', str(dest / 'disk.qcow2')]))
    if info.get('backing-filename') != str(base) or info.get('backing-filename-format') != 'qcow2':
        raise ValueError('Overlay must reference only the verified base image')
    if (dest / 'result.json').is_symlink() or (dest / 'running.lock').is_symlink():
        raise ValueError('Symlinked runtime output rejected')
    if (dest / 'serial.log').exists() or (dest / 'serial.log').is_symlink():
        raise ValueError('Existing serial log; preserve it and use a fresh VM name')
    # Exclusive guard prevents concurrent writes to this VM's NVRAM and overlay.
    with (dest / 'running.lock').open('x'):
        try:
            try:
                result = subprocess.run(cmd, timeout=args.timeout)
                status = result.returncode
            except subprocess.TimeoutExpired:
                status = 124
            except KeyboardInterrupt:
                status = 130
            text = (dest / 'serial.log').read_text(errors='replace') if (dest / 'serial.log').exists() else ''
            checks = check_transcript(text.replace('\r', ''))
            report = {'qemu_exit_code': status, 'checks': checks,
                      'login': 'UNVERIFIED: requires an actual SSH session',
                      'command': cmd, 'timeout_seconds': args.timeout}
            (dest / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
            print(json.dumps(report, indent=2))
            return 0 if status == 0 and all(checks.values()) else 1
        finally:
            (dest / 'running.lock').unlink()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('action', choices=('doctor', 'fetch', 'prepare', 'run'))
    p.add_argument('--name', default='dev')
    p.add_argument('--dry-run', action='store_true')
    p.add_argument('--code', help='AAVMF_CODE.fd from development host')
    p.add_argument('--vars', help='Matching AAVMF_VARS.fd template')
    p.add_argument('--proxy', help='Optional credential-free host HTTP proxy, e.g. http://10.0.2.2:PORT')
    p.add_argument('--smoke', action='store_true', help='Run guest checks and power off')
    p.add_argument('--network', action='store_true', help='Explicitly permit guest outbound networking')
    p.add_argument('--ssh-port', type=int, help='Opt-in loopback-only SSH forwarding')
    p.add_argument('--timeout', type=int, default=900)
    args = p.parse_args()
    try:
        lock = load_lock()
        if args.action == 'doctor':
            found = {t: shutil.which(t) for t in TOOLS}
            print(json.dumps(found, indent=2))
            return 0 if all(found.values()) else 1
        if args.timeout < 1:
            raise ValueError('Timeout must be positive')
        if args.action == 'run':
            return run(args, lock)
        if args.dry_run:
            print(json.dumps({'action': args.action, 'directory': str(output_path(args.name)), 'image': lock}, indent=2))
            return 0
        os.umask(0o077)
        if args.action == 'fetch':
            print(fetch(lock))
        elif args.action == 'prepare':
            if not args.code or not args.vars:
                raise ValueError('prepare requires --code and --vars')
            prepare(args, lock)
        return 0
    except (ValueError, OSError, subprocess.SubprocessError) as e:
        print(f'ERROR: {e}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
