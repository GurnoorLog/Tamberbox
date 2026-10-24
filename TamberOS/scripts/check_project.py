#!/usr/bin/env python3
"""Offline project structure check. Does not validate OS boot or QML compilation."""
from pathlib import Path
from xml.etree import ElementTree

root = Path(__file__).resolve().parents[1]
required = [
    'README.md', 'AGENTS.md', 'docs/architecture.md', 'docs/board-support.md',
    'docs/ui-ux.md', 'docs/branding.md', 'docs/roadmap.md', 'prompts/00_WORK_HANDOFF.md',
    'prototype/index.html', 'prototype/style.css', 'prototype/app.js',
    'shell/tamber-shell/Main.qml', 'branding/tamber-llama.svg',
    'branding/tamber-crown.svg', 'references/tamberbox-poster.png',
]
missing = [path for path in required if not (root/path).is_file()]
if missing:
    raise SystemExit('Missing files: ' + ', '.join(missing))
for path in (root/'branding').glob('*.svg'):
    ElementTree.parse(path)
print('PASS: Required project artifacts and SVG syntax exist.')
print('LIMITATION: hardware boot, Qt6 build and graphical interaction NOT verified by this check.')
