#!/bin/bash
# Isolated dependency prefix; never installs into the host system.
set -euo pipefail
cd "$(dirname "$0")/.."
base="$PWD/build/layer-shell-qt"
revision=395a913581da34f4d10c6b9ae8ba216e8b1f69f9
if [[ ! -d "$base/.git" ]]; then git clone https://github.com/KDE/layer-shell-qt.git "$base"; fi
git -C "$base" checkout --detach "$revision"
[[ $(git -C "$base" rev-parse HEAD) == "$revision" ]]
cmake -S "$base" -B build/layer-shell-build -G Ninja -DQT_MAJOR_VERSION=6 -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PWD/build/session-deps" -DCMAKE_INSTALL_LIBDIR=lib
cmake --build build/layer-shell-build --parallel 2
cmake --install build/layer-shell-build
