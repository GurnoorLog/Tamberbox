#!/bin/bash
set -euo pipefail
cd /work
[[ $(uname -m) == aarch64 && -f /.dockerenv ]] || exit 2
dnf --releasever=10.2 --enablerepo=crb -y install git gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtwayland-devel qt6-qtsvg glib2-devel wayland-devel wayland-protocols-devel libxkbcommon-devel python3 file
mkdir -p build/m3-alma-evidence
rpm -qa | sort > build/m3-alma-evidence/rpm-inventory.txt
git clone https://github.com/KDE/extra-cmake-modules.git build/ecm
git -C build/ecm checkout --detach 09025604cf16a63c8bd0d8d871c7edc44ca47aab
cmake -S build/ecm -B build/ecm-build -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX="$PWD/build/session-deps"
cmake --install build/ecm-build
export CMAKE_PREFIX_PATH="$PWD/build/session-deps"
bash scripts/build_layer_shell.sh
cmake -S shell/tamber-shell -B build/shell -G Ninja -DTAMBER_WAYLAND_SESSION=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build/shell --parallel 2
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_QUICK_CONTROLS_STYLE=Basic ctest --test-dir build/shell --output-on-failure | tee build/m3-alma-evidence/ctest.txt
file build/shell/tamber-desktop | tee build/m3-alma-evidence/binary.txt
