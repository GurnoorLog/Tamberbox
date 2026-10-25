# TamberOS M3 development status · 2026-10-25

**M3 desktop development proceeds remotely. M2 hardware validation remains pending.**
The M2 image scripts, original nine concepts and sunglasses-llama mascot are
unchanged. No physical hardware access, device write, bootloader modification,
SDDM activation or initramfs replacement was performed.

## Implemented

- Native Qt/QML Wayland desktop on the existing Sway compositor, with layer-shell
  wallpaper, slim translucent top bar, centered animated dock and search overlay.
- Real GIO application discovery and launching; launched applications use xdg-shell
  rather than inheriting the desktop's layer role. Theme icons have an original
  fallback. Running-window indicators come from Sway's actual window tree.
- Focus, minimize/restore, fullscreen, floating and close operations for known
  window IDs. Workspaces and keyboard bindings are provided by the session config.
- Appearance controls, wallpaper intensity and reduced motion; user settings
  persist through Qt Settings. Display-scale, PipeWire audio and NetworkManager
  radio controls issue real bounded requests and report service/permission errors.
- Original restrained Quiet Ridge wallpaper. SDDM login theme and Plymouth theme
  source, with a staging script and explicitly labeled Qt-rendered design previews.

## Verification scope

The [CI manifest](evidence/m3/ci.json) records tested commit `bc996e94e11f6375ce65ef1d91d3fcbf80d3940b`. [Desktop CI run 40207240150](https://github.com/GurnoorLog/Tamberbox/actions/runs/40207240150) and [existing checks 40207240110](https://github.com/GurnoorLog/Tamberbox/actions/runs/40207240110) both passed. Native ARM64
Ubuntu/Sway/pixman tests launch a real terminal through keyboard search, verify
reserved panel geometry, minimize/restore/fullscreen/close a real window, and run
three CTest targets. A separate AlmaLinux 10.2 ARM64 container compiles the desktop
against Qt 6.10.1 and passes the three offscreen CTest targets. The compositor
integration case is deliberately skipped there; it executes in the Sway job.
The AlmaLinux binary is an actual aarch64 ELF, not a cross-platform mock.
32 Python tests and the original asset-preservation gate pass.

The runtime screenshots under `docs/evidence/m3/runtime` show actual rendered
Wayland clients. The login and boot images are design previews, not authenticated
sessions or device boot captures. Build logs, RPM inventory, compositor output
metadata, actual window geometry and test results are included alongside them.

## Limitations

No Orange Pi boot, GPU acceleration or physical peripheral result is inferred.
Wayland runtime is verified on Ubuntu ARM64; AlmaLinux desktop compilation and
its offscreen tests are verified separately. Integration with a complete AlmaLinux
Sway/PipeWire/NetworkManager login session remains to be tested.

Audio/network requests need real service/device tests. Display-scale persistence,
multiple monitors/hotplug, automatic session recovery, dock pinning/reordering,
notifications, per-application menu export and production packaging remain open.
Sway does not round every external application's frame; native client decorations
remain in use. Translucency is implemented; compositor blur is not claimed.
SDDM PAM authentication and actual Plymouth execution are unverified. Theme staging
does not activate either component. The official bootloader reference remains
`references/final-concept/01-bootloader-concept.png`.

The desktop is a development milestone, not a production OS release. Private Qt
API compatibility is handled explicitly by the pinned layer-shell build script;
rebuild it for the installed Qt version. Dependencies are recorded and selected
sources/container are pinned, but byte-identical output is not claimed.

## Reproduce and test later

Read [desktop build/session instructions](m3-desktop.md),
[M2 candidate evidence](status-m2.md), and the
[separate-card hardware validation package](m2-hardware-testing.md).
The M2 image remains the independent headless hardware baseline. Close the nested
session or revert the feature branch to roll back M3 development; no existing
TamberBox installation has been changed.
