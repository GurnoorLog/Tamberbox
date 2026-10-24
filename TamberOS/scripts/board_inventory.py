#!/usr/bin/env python3
"""Bounded read-only inventory; no commands, network, raw disks or boot writes."""
import argparse
import json
from pathlib import Path
import re


def text(root, rel):
    try:
        with (root / rel).open('rb') as f:
            return f.read(65536).decode('utf-8', errors='replace').strip('\x00\n')
    except OSError:
        return None


def redact(value):
    if value is None: return None
    value = re.sub(r'(?i)\b(?:[0-9a-f]{2}:){5}[0-9a-f]{2}\b', '[MAC REDACTED]', value)
    value = re.sub(r'(?i)\b[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\b', '[UUID REDACTED]', value)
    return re.sub(r'(?i)(serial|token|password|secret)\s*[=:]\s*\S+', r'\1=[REDACTED]', value)


def collect(root):
    compatible = text(root, 'proc/device-tree/compatible')
    compatible = compatible.split('\x00') if compatible else []
    os_data = text(root, 'etc/os-release') or ''
    release = {}
    for line in os_data.splitlines():
        key, sep, value = line.partition('=')
        if sep and key in ('ID', 'VERSION_ID', 'PRETTY_NAME'):
            release[key] = redact(value.strip('"'))
    env = text(root, 'boot/armbianEnv.txt') or ''
    boot = {}
    for line in env.splitlines():
        key, sep, value = line.partition('=')
        if sep and key in ('fdtfile', 'overlay_prefix', 'overlays'):
            boot[key] = redact(value)
    modules = text(root, 'proc/modules') or ''
    return {'schema': 1, 'source': 'bounded read-only procfs and selected text files',
            'board_model': redact(text(root, 'proc/device-tree/model')),
            'compatible': [redact(x) for x in compatible],
            'exact_ultra_compatible': 'xunlong,orangepi-5-ultra' in compatible,
            'kernel_release': redact(text(root, 'proc/sys/kernel/osrelease')),
            'os_release': release, 'boot_config_allowlist': boot,
            'loaded_modules': sorted({line.split()[0] for line in modules.splitlines() if line.split()}),
            'uboot_version': None, 'boot_media': None,
            'limitations': ['Compatible string is not physical board verification.',
                           'No cmdline, dmesg, machine IDs, addresses, serials or raw boot assets collected.',
                           'Bootloader version, boot medium, graphics and NPU remain unverified.']}


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, default=Path('/'), help='Fixture root or current Linux root')
    args = p.parse_args()
    print(json.dumps(collect(args.root), indent=2))
