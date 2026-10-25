# Tamber Shell session prototype

Qt 6.5+ Quick/QML, CMake, a C++17 compiler and GIO/GIO-Unix development packages
are required. Run inside an existing Linux graphical session, not on TamberBox.

```sh
cmake -S shell/tamber-shell -B build/shell -DCMAKE_BUILD_TYPE=Release
cmake --build build/shell --parallel 2
ctest --test-dir build/shell --output-on-failure
./build/shell/tamber-shell
```

Ctrl+Space opens the searchable application launcher. Use Up/Down and Enter;
Escape closes. Ctrl+Comma opens controls. Tab focus is visible. Reduced-motion
and opaque-panel settings persist through Qt Settings. Apps are discovered through
GIO desktop entries; GIO handles Exec syntax without constructing shell commands.
Hidden/NoDisplay entries and unknown IDs are rejected. Refresh rescans installed apps.

The floating dock displays the first four discovered apps. Its short indicator
means launch accepted, not verified running-window state. This ordinary Qt window
uses the existing desktop's window manager; it is not a compositor. Controls do
not claim network/audio/display functionality. Icons, pinning/reordering, window
switching, logout, GPU acceleration and Ultra integration remain unfinished.

Native AlmaLinux ARM64 CI compiles the shell and runs two CTest cases against
Xvfb on the isolated Ubuntu runner, using software rendering. Tests verify a real
launched subprocess and keyboard-driven launch of a separate Qt graphical window.
Screenshots are actual rendered QML, not concept artwork. See docs/evidence/m2/x11.
The original mascot is loaded from the existing SVG resource. No theme assets
were copied from WhiteSur. To undo, close the app and revert the feature branch.
