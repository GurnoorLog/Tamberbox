#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/input-test
wayland-scanner client-header tests/protocols/wlr-virtual-pointer-unstable-v1.xml build/input-test/virtual-pointer.h
wayland-scanner private-code tests/protocols/wlr-virtual-pointer-unstable-v1.xml build/input-test/virtual-pointer.c
cc tests/virtual_pointer.c build/input-test/virtual-pointer.c -Ibuild/input-test $(pkg-config --cflags --libs wayland-client) -o build/input-test/virtual-pointer
