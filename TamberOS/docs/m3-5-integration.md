# M3.5: HANCORE V2.a-style Waybar and original game library

## Status

**Original handoff status (superseded by the continuation results in [status.md](status.md)).** At handoff, code was integrated but graphical runtime and AlmaLinux deployment were not verified. This patch is developed from M3 and preserves M2 image, branding, and archived evidence. It does not install anything on the user device.

## Waybar

Visual layout based on [HANCORE-linux/waybar-themes V2.a](https://github.com/HANCORE-linux/waybar-themes/tree/main/config/V2.a), MIT. Adapted for Sway/Wayland rather than its upstream Hyprland/Omarchy assumptions. Source references and attribution in `session/waybar/README.md`.

- Three separate dark pill groups on top, red brand block, orange CPU, green LAN, centered clock. This is the requested V2.a look, not the previous orange/cream design.
- Sway-native workspace/window modules, no Omarchy shell helpers, no Pacman updates, no weather service or broken CSS import.
- Config launched in the isolated Tamber session. No `~/.config` overwrite. If Waybar is unavailable, the old built-in Qt bar remains active.
- `TAMBER_USE_WAYBAR=0 session/start-tamber-session` restores the Qt top bar.
- Waybar must be installed in the runtime image; AlmaLinux package availability still requires verification. Missing network/audio/Bluetooth services should be checked in the target session.

## Games

Custom **Tamber / Play** QML window, inspired at a high level by [Omikuji](https://github.com/omikuji-launcher/omikuji), not copied from its source or artworks. Omikuji uses GPL-3.0-or-later; this patch does not introduce any of its copyrighted code.

- The existing GIO launcher discovers installed `.desktop` entries; now also records `Game;` category.
- Library displays installed game entries, search, live theme icons, keyboard navigation and actual application launch requests.
- Open via **Super+G**, the dock's Games button, or right-click TamberOS Waybar label.
- This is an initial real library screen, **not** a complete runner/store/controller system. Future work: genuine controller input, emulator integration, game metadata/assets, art management, runner validation and native ARM64 testing.

## Required next checks

1. Install Waybar in a disposable Sway ARM64 test environment, verify the package and CSS compatibility.
2. Build Qt/QML shell with the new `openGames` signal and game category discovery on ARM64.
3. Start real Sway/Waybar/Tamber session, capture screenshots and logs, click brand launcher, verify workspace switching and no double top bars.
4. Install a known Game-category `.desktop` entry, ensure it appears and launches; verify empty state without games.
5. Run existing CTest and Python suites, assess font fallback, multi-monitor and low-resolution layout.
6. Keep physical Orange Pi and boot validation pending.
