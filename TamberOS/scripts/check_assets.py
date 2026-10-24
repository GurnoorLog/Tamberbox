#!/usr/bin/env python3
"""Verify original assets; fail the final-concept gate until all nine originals exist."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'references/assets.lock.json'


def check(root=ROOT, require_concepts=False):
    manifest = json.loads((root / 'references/assets.lock.json').read_text())
    errors = []
    for name, expected in manifest['original_assets'].items():
        p = root / name
        if p.is_symlink() or not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest() != expected:
            errors.append('Missing or changed original asset: ' + name)
    concepts = manifest.get('final_concepts', {})
    if require_concepts and (len(concepts) != 9 or '01-bootloader-concept.png' not in concepts):
        errors.append('BLOCKED: nine original concept PNGs, including 01-bootloader-concept.png, have not been imported')
    actual = {p.name for p in (root / 'references/final-concept').glob('*.png')}
    companion={Path(name).name for name in manifest['original_assets'] if name.startswith('references/final-concept/')}
    if actual != set(concepts) | companion:
        errors.append('Concept directory does not match the locked asset inventory')
    for name, expected in concepts.items():
        if Path(name).name != name:
            errors.append('Unsafe concept filename: ' + name); continue
        p = root / 'references/final-concept' / name
        if p.is_symlink() or not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest() != expected:
            errors.append('Missing or changed concept asset: ' + name)
    return errors


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--require-final-concepts', action='store_true')
    args = p.parse_args()
    errors = check(require_concepts=args.require_final_concepts)
    for e in errors: print(e)
    if not errors:
        print('PASS: original assets match their recorded SHA256 values')
        if not json.loads(MANIFEST.read_text())['final_concepts']:
            print('UNVERIFIED: nine final concepts are unavailable; run --require-final-concepts for the release gate')
    sys.exit(1 if errors else 0)
