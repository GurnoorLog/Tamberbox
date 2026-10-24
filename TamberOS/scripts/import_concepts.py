#!/usr/bin/env python3
"""Import exactly nine original PNGs from an updated starter ZIP; never synthesize art."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def read_concepts(archive):
    images = {}
    with zipfile.ZipFile(archive) as z:
        for info in z.infolist():
            parts = PurePosixPath(info.filename).parts
            if '..' in parts or PurePosixPath(info.filename).is_absolute():
                raise ValueError('Unsafe ZIP member')
            if len(parts) < 3 or parts[-3:-1] != ('references', 'final-concept') or not parts[-1].endswith('.png'):
                continue
            name = parts[-1]
            if not re.fullmatch(r'0[1-9]-[a-z0-9-]+\.png', name) or name in images or info.file_size > 25_000_000:
                raise ValueError('Invalid, duplicate or oversized concept member')
            data = z.read(info)
            if not data.startswith(b'\x89PNG\r\n\x1a\n'):
                raise ValueError('Not a PNG: ' + name)
            images[name] = data
    if len(images) != 9 or '01-bootloader-concept.png' not in images or {name[:2] for name in images} != {f'{i:02d}' for i in range(1,10)}:
        raise ValueError('Expected original concepts numbered 01..09, including 01-bootloader-concept.png')
    return images


def install(archive, root=ROOT):
    images = read_concepts(archive)
    folder = root / 'references/final-concept'
    if folder.is_symlink(): raise ValueError('Symlinked concept folder rejected')
    manifest_path = root / 'references/assets.lock.json'
    manifest = json.loads(manifest_path.read_text())
    for name, data in images.items():
        p = folder / name
        if p.is_symlink() or (p.exists() and p.read_bytes() != data):
            raise ValueError('Refusing to replace existing concept: ' + name)
    existing = {p.name for p in folder.glob('*.png')}
    if existing - set(images): raise ValueError('Untracked concept assets exist')
    folder.mkdir(parents=True, exist_ok=True)
    for name, data in images.items():
        p = folder / name
        if not p.exists():
            with p.open('xb') as f: f.write(data)
    manifest['final_concepts'] = {name: hashlib.sha256(data).hexdigest() for name, data in sorted(images.items())}
    manifest['concept_source_zip_sha256'] = hashlib.sha256(Path(archive).read_bytes()).hexdigest()
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('archive', type=Path)
    args = p.parse_args()
    install(args.archive)
    print('Imported nine exact originals and locked SHA256 values; review images before committing')
