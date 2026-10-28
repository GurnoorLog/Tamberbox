#!/usr/bin/env python3
"""Explicit opt-in GPU visualiser sidecar; never starts an audio capture process."""
import argparse
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def plan(socket, binary, environ):
    if not environ.get('WAYLAND_DISPLAY'):
        raise ValueError('An existing Wayland desktop session is required')
    if environ.get('QT_QUICK_BACKEND') == 'software':
        raise ValueError('DMA-BUF requires a GPU renderer; software rendering cannot verify it')
    path = Path(socket)
    if not path.is_absolute() or path.is_symlink():
        raise ValueError('Use an absolute, non-symlink socket path')
    info = path.stat()
    if not stat.S_ISSOCK(info.st_mode) or info.st_uid != os.getuid():
        raise ValueError('The export must be a Unix socket owned by this user')
    executable = shutil.which(binary)
    if not executable:
        raise ValueError('Supply the custom DMA-BUF-capable shell binary with --binary')
    return [executable, '-p', str(ROOT/'shell/tamber-surfaces/shell.qml')]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--socket', required=True)
    parser.add_argument('--binary', default='quickshell')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    try:
        command = plan(args.socket, args.binary, os.environ)
        if args.dry_run:
            print(json.dumps({'command': command, 'socket': args.socket, 'gpu_validated': False}))
            return 0
        env = os.environ.copy()
        env['TAMBER_DMABUF_SOCKET'] = args.socket
        env['QSG_RHI_BACKEND'] = 'opengl'
        return subprocess.call(command, env=env)
    except (ValueError, OSError) as error:
        print(str(error), file=sys.stderr)
        return 2

if __name__ == '__main__':
    sys.exit(main())
