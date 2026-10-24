#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 -m unittest discover -s tests -v
python3 scripts/check_project.py
python3 scripts/check_assets.py --require-final-concepts
python3 scripts/qemu/vm.py run --dry-run
bash -n scripts/qemu/guest-check.sh
if command -v node >/dev/null 2>&1; then node --check prototype/app.js; fi
if [ "${TAMBER_BUILD_SHELL:-0}" = 1 ]; then
    cmake -S shell/tamber-shell -B build/shell -DCMAKE_BUILD_TYPE=Release
    cmake --build build/shell --parallel 2
fi
