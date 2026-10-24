#!/usr/bin/env python3
"""Download/extract QEMU tools locally on Ubuntu 24.04 amd64; never install packages."""
import getpass
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/isolated-host'
SNAPSHOT = 'https://snapshot.ubuntu.com/ubuntu/20260828T000000Z/'
PACKAGES = ['qemu-system-arm', 'qemu-utils', 'qemu-efi-aarch64', 'cloud-image-utils', 'genisoimage']


def main():
    import argparse
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--download', action='store_true', help='Explicitly download signed package metadata and tool packages')
    args = p.parse_args()
    if not args.download:
        print(json.dumps({'mode':'plan only','snapshot':SNAPSHOT,'packages':PACKAGES,'destination':str(BASE)},indent=2))
        return
    release = Path('/etc/os-release').read_text()
    if 'ID=ubuntu' not in release or 'VERSION_ID="24.04"' not in release or platform.machine() != 'x86_64':
        raise SystemExit('This bootstrap is validated only for Ubuntu 24.04 x86_64; use native prerequisites on other hosts')
    for name in ('/usr/bin/apt-get', '/usr/bin/dpkg-deb', '/usr/share/keyrings/ubuntu-archive-keyring.gpg'):
        if not Path(name).is_file(): raise SystemExit('Missing prerequisite: ' + name)
    for parent in (ROOT/'build', BASE, BASE/'apt', BASE/'root'):
        if parent.is_symlink(): raise SystemExit('Symlinked output rejected')
    apt = BASE/'apt'
    for rel in ('lists/partial','cache/archives/partial','empty'):
        (apt/rel).mkdir(parents=True,exist_ok=True)
    shutil.copyfile('/var/lib/dpkg/status', apt/'status')
    (apt/'sources.list').write_text(''.join(f'deb [signed-by=/usr/share/keyrings/ubuntu-archive-keyring.gpg] {SNAPSHOT} {suite} main universe\n' for suite in ('noble','noble-updates','noble-security')))
    (apt/'apt.conf').write_text(f'''Dir::Etc::parts "{apt}/empty";
Dir::Etc::main "{apt}/none";
Dir::Etc::sourcelist "{apt}/sources.list";
Dir::Etc::sourceparts "{apt}/empty";
Dir::State "{apt}";
Dir::State::status "{apt}/status";
Dir::State::lists "{apt}/lists";
Dir::Cache "{apt}/cache";
Dir::Log "{apt}";
APT::Sandbox::User "{getpass.getuser()}";
Acquire::Languages "none";
Acquire::https::Timeout "30";
Acquire::Retries "1";
''')
    env = dict(os.environ, APT_CONFIG=str(apt/'apt.conf'))
    for name, command in [('update', ['update']), ('download', ['--download-only','--no-install-recommends','-y','install',*PACKAGES])]:
        with (BASE/(name+'.txt')).open('w') as log:
            subprocess.run(['/usr/bin/apt-get',*command],env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
    records=[]
    for package in sorted((apt/'cache/archives').glob('*.deb')):
        subprocess.run(['/usr/bin/dpkg-deb','-x',str(package),str(BASE/'root')],check=True)
        records.append({'file':package.name,'sha256':hashlib.sha256(package.read_bytes()).hexdigest()})
    (BASE/'packages.json').write_text(json.dumps(records,indent=2)+'\n')
    print('Downloaded and extracted tools; no package installation or maintainer scripts ran.')
    print(f'PATH prefix: {BASE}/root/usr/bin')
    print(f'LD_LIBRARY_PATH prefix: {BASE}/root/usr/lib/x86_64-linux-gnu')


if __name__ == '__main__': main()
