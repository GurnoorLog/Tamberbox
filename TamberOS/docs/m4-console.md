# M4: desktop refinement and fullscreen console

This increment extends verified M3 commit bb5bd388ab3819b20cccc4a509d2f2a28a119e20.
It retains the original library, controller reader, safe GIO launch path, Sway
session, Waybar modules, M2 source and all original design references. It adds no
Sony source, artwork, icons or firmware. Console navigation is an original Tamber
implementation inspired by familiar living-room interaction patterns.

## Build and run

Use the same dependencies, pinned LayerShellQt revision and commands as
[m3-play.md](m3-play.md). CI definitions at the repository root and inside the
standalone project build natively on ARM64. AlmaLinux builds/offscreen tests and
Ubuntu Sway graphical tests are separate; neither establishes Orange Pi support.

```sh
bash scripts/build_layer_shell.sh
cmake -S shell/tamber-shell -B build/shell -G Ninja \
  -DTAMBER_WAYLAND_SESSION=ON -DCMAKE_PREFIX_PATH="$PWD/build/session-deps"
cmake --build build/shell --parallel 2
sh scripts/build_virtual_pointer.sh
dbus-run-session python3 scripts/test_wayland_session.py
```

The graphical test creates private XDG directories, a headless Sway output and a
PulseAudio null sink. Its real keyboard/pointer input, compositor state, screenshots
and logs go into `build/m4-evidence`. It never connects to physical DRM/input or
storage. To run interactively inside an existing Wayland compositor:

```sh
WLR_BACKENDS=wayland session/start-tamber-session
```

## Desktop

The refined Waybar retains the M3 launcher, workspace, title, clock, tray,
CPU/RAM/network/audio/Bluetooth modules. Neutral surfaces replace the colored
module blocks; restrained orange marks selection and the Tamber wordmark. The
dock, application list, panel palette and Sway titlebars use coherent colors.
Sway owns external application frames; stock Sway does not provide rounded
external window corners or background blur. Tamber's own panels are rounded and
translucent; no blur or rounded third-party windows are claimed.

Super+Space opens app search; Super+Comma opens settings; Super+G toggles the
console. Super+Shift+G opens the retained M3 library and advanced emulator forms.

## Fullscreen behavior

`Console.qml` is an opaque LayerShellQt overlay anchored to all four output edges,
with exclusive zone -1 and exclusive keyboard input. It occupies the full output,
including the regions otherwise reserved by Waybar and the dock. This is a real
full-output shell surface, not a large floating window or a screenshot. Waybar
continues running underneath; the dock and Qt fallback bar hide while Game Mode
is active. The visible Return to Desktop action and Super+G are escape routes.
Multi-output placement/hotplug remains unvalidated.

Home sorts games by their recorded successful launch request. Library filters
include installed, recent, native and named collections; Emulators and Favorites
have dedicated sections. Apps exposes visible installed desktop entries; Media
filters their AudioVideo category. Missing software (including an AI application)
is not represented by fabricated shortcuts. Search matches titles and collections.
Favorites, local artwork and emulator profiles reuse the existing backend. A
collection name is persisted per game; blank removes it. Multiple memberships,
platform-specific emulator catalogs and downloadable cover providers are pending.

Selecting a tile opens its detail/actions area. Play uses GIO or the existing
explicit RetroArch argv path. The console yields keyboard focus while waiting for
an exact desktop-ID-to-Wayland-app-ID match, enables fullscreen only for that known
window, and returns when it disappears. Resume focuses a matching existing
window; it does not save or restore game state. If no matching window appears
within 15 seconds, the console returns with an explicit message. Applications
whose Wayland app ID differs from their desktop ID (including many emulators)
need a future explicit mapping; no arbitrary new window is assumed to be the game.
Return to Desktop reverses the fullscreen state introduced by the console.

## Keyboard and controller routing

| Input | Behavior |
|---|---|
| Left / Right | Move within navigation, content rail or actions |
| Up / Down | Move between navigation, browsing and actions |
| Enter | Enter browsing, open details or invoke selected action |
| Esc | Close details, clear search, return Home, then exit |
| PgUp / PgDn | Previous / next section |
| Ctrl+F | Focus search; Down returns to browsing |
| F | Favorite selected game |
| M | Artwork/collection management for selected game |
| R in Library | Cycle installed/recent/native/collections filter |
| Tab | Cycle focus zones |
| Super+G | Open console or return to desktop |

The `navigate(action)` boundary accepts left/right/up/down/accept/back/favorite
from both keyboard and M3's Linux joystick reader. Forms use normal keyboard
focus and temporarily disable controller dispatch. Common joystick events are
covered synthetically; physical mappings, repeated-stick movement, remapping,
evdev-only devices and Bluetooth gamepads are not established. The system screen
states this rather than implying controller certification.

## System and limitations

System cards expose real service state, home-filesystem capacity and OS/kernel
identity, a persisted reduced-motion toggle and available audio mute control.
Missing NetworkManager/PipeWire services report unavailable. Network setup and
display scaling remain in desktop settings. Power currently returns to desktop;
shutdown/reboot actions are explicitly pending. There are no fake toggles for
unimplemented capabilities. Audio on CI uses a null sink; device output is untested.

M2 hardware acceptance remains pending. The image candidate is not rebuilt or
modified by M4. SDDM authentication, Plymouth execution, accelerated graphics,
physical controllers, emulator gameplay and complete Alma graphical deployment
remain outside the verified remote scope. See status.md for the actual run results.

## Rollback

Close the nested session or check out the preserved M3 branch. No system settings
or existing Waybar config are overwritten. Back up the Tamber Desktop application
config before downgrading; new `lastPlayed` and `collection` keys in play.json are
additive. Games, ROMs and original cover files are never deleted by this frontend.
