#!/bin/bash
set -euo pipefail
cd /work
[[ $(uname -m) == aarch64 && -f /.dockerenv ]] || exit 2
dnf --releasever=10.2 -y install git python3 gnupg2 gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg glib2-devel rpm-build
TAMBER_BUILD_SHELL=1 sh scripts/ci.sh
ctest --test-dir build/shell --output-on-failure
build/shell/tamber-shell --screenshot build/shell/desktop.png
