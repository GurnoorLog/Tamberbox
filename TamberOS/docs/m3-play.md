# Tamber / Play development

This increment extends the supplied M3.5 work. It does not replace the M2 image.
Native ARM64 CI builds the full updated desktop on Ubuntu and AlmaLinux, while
an isolated headless Sway job installs Waybar and GNOME 2048 and exercises the UI.
Exact results and limitations are recorded in status.md and evidence/m3-play.

## Build and run

Follow m3-desktop.md for the existing Qt 6.4+ and pinned LayerShellQt build.
On a disposable Ubuntu 24.04 ARM64 runner, install `waybar pulseaudio
pulseaudio-utils gnome-2048 python3-pyatspi gir1.2-atspi-2.0` in addition to the
existing build/runtime dependencies. Build with `TAMBER_WAYLAND_SESSION=ON`.
Run `dbus-run-session python3 scripts/test_wayland_session.py` as an unprivileged
user. The script uses headless/pixman, private XDG directories, a null audio sink,
and the real session configuration. It does not open DRM or physical storage.
The full command sequence is in `.github/workflows/m3-desktop.yml`.

For a nested interactive desktop: `WLR_BACKENDS=wayland session/start-tamber-session`.
Waybar replaces the Qt top bar; `TAMBER_USE_WAYBAR=0` selects the original bar.
The HANCORE adaptation's upstream MIT notice is retained in
`session/waybar/LICENSE.HANCORE`. No Omikuji source or art is used.

## Library

Super+G or right-click the TamberOS label opens Play. Arrows navigate, Enter
launches and Escape closes; Ctrl+F focuses search. The app launcher still uses
Super+Space. Games come from visible GIO `.desktop` entries with the exact Game
category, plus profiles explicitly added by the user. There is no filesystem
crawler or automatic game/cover download.

Favorites sort first and persist. Hide removes an entry from this view only;
Restore hidden reverses it without deleting a game. Manage imports a local
image (up to 20 MiB and 8192 pixels per dimension) into the user's Play artwork
folder. The original source image is not changed. Icons remain the fallback.
Settings live under `$XDG_CONFIG_HOME/TamberOS/Tamber Desktop/play.json` with
Qt's default of `~/.config` when XDG_CONFIG_HOME is unset.

RetroArch integration is an explicit launch profile: supply a name, absolute
executable path, ROM path and libretro core path. The launcher uses a separate
argv element for `-L`, the core and ROM, never a constructed shell command.
No ROM, firmware, core or emulator binary is bundled. A successful launch request
is not proof of a compatible core, playable game or accelerated emulator.

## Controller increment

A nonblocking Linux joystick reader supports `/dev/input/js*`, disconnect/reconnect,
left-stick and common D-pad axes, button 0 confirm, button 1 back and button 2
favorite. Input changes the library only while it is visible; management forms
use keyboard/mouse. No elevated input permissions are requested or installed.
The synthetic pipe tests feed real `js_event` structures through the parser and
check dead zones, edge transitions, initialization, inactive state and disconnect.
These are not physical controller tests. Model-specific remapping, evdev-only
devices, repeat navigation and Bluetooth gamepad validation remain future work.

## Rollback and boundaries

Close the nested session or revert the feature branch. To clear only Play state,
back up and remove its `play.json` and `art` directory from the application config
folder. Games/ROMs and their source images are never deleted by Play. The existing
M2 candidate, mascot, original concepts and boot reference are unchanged.
SDDM, Plymouth, board boot/GPU, microSD installation, and full AlmaLinux graphical
integration remain separate pending validation.
