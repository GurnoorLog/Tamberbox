# TamberOS M4 desktop / console development — 2026-10-26

The M4 remote development increment passes native ARM64 builds and actual
Sway/Waybar graphical execution. This is not full distribution or physical-board
acceptance. M1 remains accepted; M2 hardware validation remains pending. No
TamberBox installation or physical storage was accessed or modified.

## Implemented

- Refined neutral Waybar, application launcher, running-app dock icons, rounded
  Tamber panels and coordinated Sway titlebars; the M3 modules remain functional.
- Full-output, opaque Game Mode with horizontal selection, clear focus, keyboard
  navigation and reduced-motion-aware transitions. It visually covers Waybar and
  hides the dock, while preserving a visible Return to Desktop action.
- Home, Library, Apps, Media, Emulators, Favorites and System sections; selected
  game actions/details, search, recent launches, native filtering and named
  collections. Favorites, artwork import and emulator profiles reuse M3 services.
- Actual installed game/app launching, exact Wayland app-ID matching, fullscreen
  handoff, return on game close and restoration of the previous fullscreen state
  when leaving Game Mode. Resume focuses an existing window, not a saved game.
- System cards show real service availability, storage and OS information.
  Controller mapping and shutdown/reboot integration explicitly remain pending.

## Verified evidence

Tested code commit: `d19c107f053ab3d93fb3124c4b7debc2a03122b0`.

[Desktop/console run 40325938997](https://github.com/GurnoorLog/Tamberbox/actions/runs/40325938997)
and [existing checks run 40325939248](https://github.com/GurnoorLog/Tamberbox/actions/runs/40325939248)
passed. Subsequent delivery changes contain documentation and evidence only.

| Check | Actual scope and result |
|---|---|
| AlmaLinux ARM64 | Native pinned AlmaLinux 10.2 container; desktop compiled; four CTest targets passed offscreen |
| Graphical ARM64 | Ubuntu 24.04, Qt 6.4.2, Sway 1.9, Waybar 0.9.24, headless output/pixman, 1280×720 |
| Existing shell | Legacy Alma ARM64/X11 CI job passed |
| Offline checks | 35 Python tests plus project, syntax and original-asset gates passed |
| Waybar | One bar; real launcher/workspace pointer input, tray fixture activation and PulseAudio null-sink scroll |
| Library | Existing search, favorites, local cover import and actual GNOME 2048 process/window passed |
| Console | Full-output frame; keyboard selection/details/sections/filter/search; real game/app launches passed |
| Handoff | 2048 window verified fullscreen at x=0,y=0,width=1280,height=720; console returned on game close |
| Exit | Mode shortcut restored desktop and reversed fullscreen introduced on the terminal app |
| Settings | Reduced-motion toggle verified in runtime state and screenshot |
| Backend additions | Recent launch and collection persistence, length bound and unknown-ID behavior tested in CTest |

Actual runtime screenshots, compositor state, logs, CTest output and artifact
provenance are under `docs/evidence/m4`. `result.json` is emitted only after the
full graphical procedure and teardown complete. The diagnostic GDB wrapper runs
only the disposable desktop process. Earlier genuine failures and the layout
crash backtrace are retained; they are not counted as successful validation.

## Remaining limitations

- Orange Pi boot, GPU acceleration and peripherals remain untested. M2 image work
  is unchanged and its image binary is not duplicated in this source archive.
- The graphical test is Ubuntu ARM64; AlmaLinux compilation/offscreen testing is
  separate. Full Alma graphical deployment, RPM packaging and multimonitor/hotplug
  acceptance remain pending.
- Stock Sway does not round external application windows or blur backgrounds.
  Rounded/translucent Tamber panels are implemented; external window rounding is
  not claimed.
- Controller input uses the M3 reader and shared navigation actions; only synthetic
  joystick events are tested. Physical mappings, remapping and repeat are pending.
- Emulator profiles/argv tests are retained; real RetroArch core/gameplay is not
  tested. Exact desktop-ID/app-ID matching cannot identify every emulator/app.
  An unmatched launch returns the console with a message after 15 seconds.
- The System screen correctly reports unavailable NetworkManager/PipeWire services
  in this runner. Waybar audio tests use a null sink. Pairing, Wi-Fi transitions,
  physical audio, shutdown/reboot, SDDM authentication and Plymouth execution are
  not established.
- Media is an installed AudioVideo-app catalog, not a media player. Collections
  currently allow one named group per game. AI shortcuts appear only if installed;
  no AI adapter, account system or online store is fabricated.

Read [m4-console.md](m4-console.md) for build/session instructions, controls,
controller architecture and rollback. [status-m3-play.md](status-m3-play.md)
preserves the preceding M3 report. All original branding, mascot, nine references,
boot reference, themes and M2 image-building source match the verified M3 tree.
