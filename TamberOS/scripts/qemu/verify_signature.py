#!/usr/bin/env python3
"""Authenticate pinned AlmaLinux checksums in a disposable, isolated GPG keyring."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

FINGERPRINT = 'EE6DB7B98F5BF5EDD9DA0DE5DEE5C11CC2A1E572'
TRUST = Path(__file__).with_name('trust')
FINGERPRINT_SOURCES = ['https://almalinux.org/security/',
                       'https://wiki.almalinux.org/release-notes/10.0.html']


def verify(checksum=TRUST / 'CHECKSUM', signature=TRUST / 'CHECKSUM.asc',
           key=TRUST / 'RPM-GPG-KEY-AlmaLinux-10'):
    with tempfile.TemporaryDirectory(prefix='tamber-gpg-') as home:
        cmd = ['gpg', '--homedir', home, '--batch', '--no-autostart', '--no-auto-key-retrieve']
        shown = subprocess.check_output(cmd + ['--with-colons', '--import-options', 'show-only',
                                               '--import', str(key)], stderr=subprocess.PIPE, text=True)
        lines = shown.splitlines()
        fingerprints = [line.split(':')[9] for line in lines if line.startswith('fpr:')]
        if sum(line.startswith('pub:') for line in lines) != 1 or not fingerprints or fingerprints[0] != FINGERPRINT:
            raise ValueError('Signing key does not match independently published fingerprint')
        keyring = str(Path(home) / 'trusted.gpg')
        subprocess.run(cmd + ['--output', keyring, '--dearmor', str(key)], check=True, capture_output=True)
        result = subprocess.run(['gpgv', '--homedir', home, '--keyring', keyring, '--status-fd=1', str(signature), str(checksum)],
                                capture_output=True, text=True)
        valid = [line.split() for line in result.stdout.splitlines() if line.startswith('[GNUPG:] VALIDSIG ')]
        if result.returncode != 0 or len(valid) != 1 or valid[0][-1] != FINGERPRINT:
            raise ValueError('Checksum signature verification failed: ' + result.stderr)
        return {'signature_verified': True, 'primary_fingerprint': FINGERPRINT,
                'fingerprint_sources': FINGERPRINT_SOURCES,
                'trust_basis': 'Fingerprint cross-checked on official HTTPS security page and release notes; no out-of-band human attestation',
                'checksum_sha256': hashlib.sha256(checksum.read_bytes()).hexdigest(),
                'gpg_status': result.stdout, 'gpg_diagnostics': result.stderr}


def verify_lock(lock, checksum=TRUST / 'CHECKSUM'):
    result = verify(checksum)
    matching = [line.split() for line in checksum.read_text().splitlines()
                if len(line.split()) == 2 and line.split()[1] == lock['filename']]
    if len(matching) != 1 or matching[0][0] != lock['sha256']:
        raise ValueError('Pinned image is absent or differs from signed checksum')
    return result


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--image', type=Path)
    args = p.parse_args()
    lock = json.loads(Path(__file__).with_name('image.lock.json').read_text())
    result = verify_lock(lock)
    if args.image:
        with args.image.open('rb') as f: digest = hashlib.file_digest(f, 'sha256').hexdigest()
        if digest != lock['sha256']: raise SystemExit('Image SHA256 mismatch')
        result.update(image_sha256=digest, image_bytes=args.image.stat().st_size)
    print(json.dumps(result, indent=2))
