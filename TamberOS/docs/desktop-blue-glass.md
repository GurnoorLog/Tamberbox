# Blue glass desktop increment

The requested visual direction supersedes the original orange desktop palette.
Desktop surfaces now use deep blue, cyan focus states, pale typography, a 28px
bar, a compact low dock and a right-anchored quick control panel. The desktop
mascot overlay is removed; original assets, boot references and M2 files remain
preserved. AI integration is deferred. Play mode is preserved as a separate mode.

Reference review: the-glorious-dotfiles, `config/awesome/surreal`, master,
reviewed 2026-10-27. Reviewed repository tree, README, theme definitions and top/
bottom panel implementation plus published screenshot. This is an AwesomeWM/X11
configuration, not a Qt/Wayland desktop. We have not audited every upstream
module and do not import its code or artwork. Its source is AGPL-3.0. The new SVG
landscape and Qt implementation are original. Exact wallpaper/blur/window-shape
parity is not claimed: stock Sway does not provide the reference's Picom blur or
rounded native client corners. Translucency is actual alpha compositing, not blur.

Super+comma opens quick controls; Escape closes it. Network and audio actions use
the existing bounded NetworkManager/PipeWire APIs; service failures are reported.
Motion, panel opacity and wallpaper intensity preferences persist. All settings
opens the retained appearance, audio/network and window-management interface.
Super+Space opens searchable applications; Super+G retains fullscreen Play.

Validation: 35 offline tests and project/SVG check pass locally. ARM64 compile
and updated graphical runtime evidence must be recorded before claiming runtime
validation of this increment. Prior screenshots are not evidence for this theme.
No physical storage or Orange Pi was accessed.

Rollback: revert the blue glass desktop commit. Preferences and library data
remain compatible; preserved original wallpaper can be selected by reverting the
Desktop.qml resource reference. Build/session instructions: docs/m4-console.md.
