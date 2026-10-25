# M3 desktop development

M3 proceeds independently of Orange Pi access. M2's image and scripts remain
unchanged; physical validation is pending, not a software-development blocker.

## Architecture

`tamber-desktop` is a Qt/QML Wayland client using the existing Sway compositor.
KDE LayerShellQt gives the wallpaper, top bar, dock and overlays real layer-shell
roles. Top/bottom exclusive zones reserve application space. Sway manages native
Wayland applications; its IPC tree supplies actual window identity and focus.
Window actions accept only observed numeric IDs and a fixed action allowlist.
GIO discovers and launches installed Desktop Entries without constructing shell
commands. The M2 `tamber-shell` application remains available as an X11 preview.

The original mascot and nine screen concepts remain unchanged. The new Quiet Ridge
wallpaper is an original SVG with restrained line work. No WhiteSur assets or code
are redistributed. Panels are translucent, not blurred. Sway does not implement
universal rounded application frames; clients retain their own decorations.

## Build on an isolated Linux desktop / VM

Use the dependency list in `.github/workflows/m3-desktop.yml` for Ubuntu 24.04,
including Qt 6 development/private headers, Wayland, ECM, Sway, grim, wtype, foot,
GIO and SVG support. Then, from the TamberOS directory:

```sh
bash scripts/build_layer_shell.sh
cmake -S shell/tamber-shell -B build/shell -G Ninja \
  -DTAMBER_WAYLAND_SESSION=ON -DCMAKE_PREFIX_PATH="$PWD/build/session-deps" \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build/shell --parallel 2
sh scripts/ci.sh
dbus-run-session python3 scripts/test_wayland_session.py
```

The last command starts an isolated **headless** compositor, uses virtual keyboard
input, launches a real terminal and captures screenshots/logs. It sets private
XDG directories and explicitly uses the headless/pixman backend, with no physical
DRM/input devices. Do not point these tests at an existing user's compositor.

For an interactive nested desktop inside an existing Wayland session:

```sh
WLR_BACKENDS=wayland session/start-tamber-session
```

Use an isolated VM/session. To start a dedicated session from a spare virtual TTY,
run `session/start-tamber-session` as the normal user with working seat permissions.
Do not run it on the existing TamberBox while validating this package remotely.
The script loads only this repository's config and does not replace a user config.

For native AlmaLinux ARM64 compilation, use the pinned container and
`scripts/test_desktop_alma.sh` as shown in CI. This installs dependencies only into
a disposable container, and builds KDE ECM and LayerShellQt into `build/session-deps`.
The dependency sources are pinned by commit. Distribution package updates and
compiler versions are recorded by CI but are not fully hermetic or bit-reproducible.

## Controls

| Action | Shortcut / interface |
|---|---|
| Application search | Super+Space; arrows, Enter, Escape |
| Control center/settings | Super+Comma |
| Terminal | Super+Enter (foot) |
| Cycle windows | Super+Tab |
| Fullscreen | Super+F |
| Toggle floating | Super+Shift+Space |
| Close focused app | Super+Q |
| Workspaces | Super+1…4 or menu-bar buttons |
| Exit test session | Super+Shift+E |
| Restore/focus window | Running-window dock item |
| Minimize/restore/close | Settings → Windows |

Appearance settings persist through Qt Settings. Display scale applies to all
outputs in the current session only. NetworkManager radio commands and PipeWire
volume/mute commands report errors and unavailable services; no simulated hardware
state is shown. These controls still need real service/device validation. The dock
shows up to four alphabetical installed-app shortcuts and six running windows;
all windows remain accessible in Settings. Pinning/reordering is not implemented.

## Login and boot

`themes/sddm/tamber` contains an SDDM theme wired to its login API; outside SDDM it
explicitly disables authentication. `theme-preview` renders QML previews only.
`themes/plymouth/tamber` contains a Plymouth script driven by actual boot progress.
`python3 scripts/build_themes.py` stages themes and PNG assets under `build/themes`.
It does not install a display manager, rebuild an initramfs or activate a theme.
PAM authentication and Plymouth runtime/boot integration need separate validation.
The official `references/final-concept/01-bootloader-concept.png` remains the future
boot-experience reference; no U-Boot graphical implementation is claimed.

## Later hardware validation and rollback

Use `docs/m2-hardware-testing.md` for the separate microSD procedure, exact image
checksum, public-key personalization and boot/peripheral matrix. Only after that
image boots should a separate desktop experiment establish a usable DRM/Mesa/vendor
stack and install compatible Sway/Qt dependencies. Do not infer GPU compatibility
from headless software rendering. Keep M2's candidate as the baseline.

All changes are on a feature branch. Close the nested compositor and remove only
its disposable build directory to roll back development. No SDDM, Plymouth,
firmware, bootloader or physical storage configuration is changed by the build.
