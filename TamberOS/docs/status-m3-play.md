# TamberOS M3 Waybar / Play development — 2026-10-26

This continues the supplied M3.5 ZIP. M1 remains accepted. The M2 image candidate
and image-build source remain unchanged; Orange Pi 5 Ultra hardware acceptance
is pending. Nothing was flashed, repartitioned or installed on TamberBox.

## Implementation

- The Sway-compatible HANCORE V2.a adaptation supplies the only top bar when
  Waybar is selected. The original Qt bar remains the explicit fallback.
- Play discovers visible Game-category desktop entries, searches and launches
  through GIO, and saves favorites, hidden entries and user-imported local covers.
- An optional original vector cover is included. Other displayed game icons are
  supplied by the installed games, not copied into the source distribution.
- Explicit RetroArch profiles launch a user-supplied executable, core and ROM
  through separate argv elements. No emulator binary, core, firmware or ROM ships.
- Linux joystick input drives library navigation, confirm/back and favorites.
  Physical mapping and permissions remain unverified; see the limits below.
- Keyboard focus returns to the library after management closes. D-Bus activation
  receives the session display environment, and image imports retain their format.

## Evidence

[Desktop CI 40275789046](https://github.com/GurnoorLog/Tamberbox/actions/runs/40275789046)
and [existing checks 40275789047](https://github.com/GurnoorLog/Tamberbox/actions/runs/40275789047)
both passed for commit `4f07a72256d1971bb4595d343adc4a8a82db65fb`.
Four CTest targets pass on AlmaLinux and Wayland. The real compositor case runs
separately with `TAMBER_TEST_SWAY=1`; it is intentionally skipped in ordinary
offscreen CTest. The actual joystick reader and emulator argv are tested with
synthetic events and a subprocess probe, not physical gamepads or emulator cores.
Full provenance is in `evidence/m3-play/ci.json`.
Runtime screenshots come from actual ARM64 Sway/Wayland execution with software
rendering, not generated mockups. AlmaLinux builds and offscreen tests are
separate from the Ubuntu ARM64 graphical run. The final `result.json` is written only after clean teardown.
The original asset-preservation gate and 35 Python tests pass.

## Verification boundaries

| Area | Scope |
|---|---|
| ARM64 compilation | Native Ubuntu ARM64 and AlmaLinux 10.2 ARM64 containers/runners |
| Graphical session | Ubuntu ARM64, Sway/headless, pixman/software rendering, 1280×720 |
| Waybar | One external bar; launcher/workspace input; actual CPU/RAM/clock/window/network labels |
| Audio | Volume scrolling against a disposable PulseAudio null sink, not speakers |
| Tray | Synthetic SNI client exercising real Waybar display and D-Bus activation |
| Bluetooth | No-controller state; pairing and radio hardware untested |
| Network | Runner's virtual Ethernet state; Wi-Fi hardware/state transitions untested |
| Games | Installed GNOME game discovery, search, cover import and real 2048 process/window |
| Controller | Synthetic Linux joystick event streams test the real reader; no physical gamepad validation |
| Emulator | Profile persistence, validation and real subprocess argv probe; no RetroArch core/gameplay test |
| M2/board | Original candidate preserved; physical boot and all board peripherals pending |

The overall M3 production acceptance gate remains open. Full AlmaLinux graphical
session packaging, GPU acceleration, multi-monitor/hotplug, SDDM authentication,
Plymouth execution, physical controller mappings and emulator gameplay are not
established by these tests. The desktop is not claimed to run on the Orange Pi.

## Reproduce and roll back

Read `m3-play.md` and `m3-desktop.md` for dependencies, exact build/test commands,
shortcuts and isolated session startup. `status-m3.md` retains the previous M3
report. The earlier M2 hardware-testing package remains applicable to a separate
microSD, after explicit destination verification and approval before writing.
Close the nested session or revert this feature branch to roll back; use
`TAMBER_USE_WAYBAR=0` to select the original Qt bar. Play never deletes game files.
