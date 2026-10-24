# TamberOS architecture

## Layer diagram

```text
┌──────────────────────────────────────────────────────────────┐
│ Tamber Shell / AI Studio / Games / System Center / Settings   │
├──────────────────────────────────────────────────────────────┤
│ Tamber services: hardware telemetry, launcher, AI adapter     │
│ User session, polkit rules (minimal), D-Bus IPC (planned)     │
├──────────────────────────────────────────────────────────────┤
│ Qt6/QML + existing Wayland compositor (initially)            │
│ SDDM, Plymouth (dependent on tested availability)            │
├──────────────────────────────────────────────────────────────┤
│ AlmaLinux 10 aarch64 rootfs + RPM/DNF + systemd               │
├──────────────────────────────────────────────────────────────┤
│ Device-specific kernel, DTB, modules, GPU stack, firmware     │
├──────────────────────────────────────────────────────────────┤
│ Board-specific U-Boot / firmware / boot media                 │
└──────────────────────────────────────────────────────────────┘
```

## Key separation
- **Boot firmware / U-Boot:** board must start kernel. Graphics in this stage are hardware- and build-dependent; do not promise animations.
- **Linux + userspace:** *AlmaLinux userspace* doesn't imply that its generic kernel or EFI cloud boot process works on this SBC.
- **Plymouth:** splash after the kernel hands over a usable display, not a bootloader replacement.
- **Display manager:** SDDM only after RPM availability, Wayland/X11 support and theming verified.
- **Wayland compositor:** the QML prototype is an ordinary app. A complete shell requires compositor cooperation or a chosen compositor protocol; fullscreen alone is not a window manager.
- **System metrics:** read-only local service; verify units, permissions, sensor IDs and board names.
- **Local AI:** Ollama HTTP on `127.0.0.1` only; no externally accessible listener by default.

## Modes and data flow

```text
Input -> Compositor -> Tamber Shell
                      |-- Applications (desktop entries)
                      |-- Game catalog (local config)
                      |-- AI view -> local Ollama service (optional)
                      |-- Hardware view -> read-only metrics adapter
                      `-- Settings -> user config / authorized system API
```

## V1 implementation decisions
- Qt 6 Quick with QML for views; C++ entrypoint; implement UI state without privileged calls.
- Use a proven Wayland compositor on the actual board during development; **select after graphics testing**, not on aesthetics alone.
- Python stdlib for first hardware metrics prototype. Convert to D-Bus only once a bounded interface is defined.
- Keep settings that need root behind documented, narrow polkit or D-Bus authorization; do not give the desktop general sudo rights.
- Package independent applications as RPMs with native metadata, not scripts that overwrite AlmaLinux managed files.

## Quality gates
A feature is "working" only with reproducible steps and measured results (test command, hardware, image/kernel versions, screenshots/logs). A mocked UI is clearly labeled. Hardware boot gates are in `docs/board-support.md`.
