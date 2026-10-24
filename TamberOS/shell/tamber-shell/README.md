# QML shell prototype

A **Qt 6 Quick application** that models Tamber navigation within an existing Wayland/X11 desktop session. **Not** a compositor, display manager, Linux distro image or working window manager. It neither reads hardware telemetry nor contacts Ollama.

Build (Qt 6.5+ with Quick and a C++ compiler installed):

```bash
cmake -S shell/tamber-shell -B build/shell
cmake --build build/shell
./build/shell/tamber-shell
```

On AlmaLinux, confirm actual repo package availability before adding installer instructions. QML compilation has **not** been performed in this starter creation environment.
