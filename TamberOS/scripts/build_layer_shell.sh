#!/bin/bash
# Isolated dependency prefix; never installs into the host system.
set -euo pipefail
cd "$(dirname "$0")/.."
base="$PWD/build/layer-shell-qt"
revision=395a913581da34f4d10c6b9ae8ba216e8b1f69f9
if [[ ! -d "$base/.git" ]]; then git clone https://github.com/KDE/layer-shell-qt.git "$base"; fi
git -C "$base" checkout --detach "$revision"
[[ $(git -C "$base" rev-parse HEAD) == "$revision" ]]
# Qt 6.10 splits private modules from automatic public-package discovery.
python3 - "$base/CMakeLists.txt" <<'PYTHON'
import sys,pathlib
p=pathlib.Path(sys.argv[1]);s=p.read_text()
marker='find_package(WaylandScanner REQUIRED)'
addition='if (Qt6_VERSION VERSION_GREATER_EQUAL "6.10")\n    find_package(Qt6 REQUIRED COMPONENTS WaylandClientPrivate)\nendif()\n'
if addition not in s:s=s.replace(marker,addition+marker)
p.write_text(s)
surface=p.parent/'src/qwaylandlayersurface.cpp'
s=surface.read_text()
old='window()->handleExpose(QRect(QPoint(), m_pendingSize));'
new='#if QT_VERSION < QT_VERSION_CHECK(6, 7, 0)\n        window()->handleExpose(QRect(QPoint(), m_pendingSize));\n#elif QT_VERSION < QT_VERSION_CHECK(6, 9, 0)\n        window()->sendRecursiveExposeEvent();\n#else\n        window()->updateExposure();\n#endif'
# Same exposure API split used by upstream LayerShellQt v6.5.0 sendExpose().
if '#if QT_VERSION < QT_VERSION_CHECK(6, 7, 0)' not in s:
 if old not in s:raise SystemExit('Layer-shell source differs from reviewed patch target')
 surface.write_text(s.replace(old,new))
PYTHON
cmake -S "$base" -B build/layer-shell-build -G Ninja -DQT_MAJOR_VERSION=6 -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PWD/build/session-deps" -DCMAKE_INSTALL_LIBDIR=lib
cmake --build build/layer-shell-build --parallel 2
cmake --install build/layer-shell-build
