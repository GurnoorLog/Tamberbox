# M3 Play execution record

- Run 40230916705: native ARM64 Ubuntu desktop build and AlmaLinux build/tests
  passed. Real Wayland reached Play, but the pointer-based search step failed to
  launch 2048. Added a Ctrl+F focus shortcut and virtual-keyboard readiness delay.
- Run 40231200480: native builds passed. GTK accessibility exposed actual Waybar
  module labels, but the Sway cursor-command click did not open the launcher in
  a seat without a pointer device. Added a real virtual-pointer client.
- Run 40231417720: Ubuntu dependency setup failed because wlrctl is unavailable
  in Noble repositories. Added an original small test client built against the
  vendored, licensed wlroots protocol XML. No physical input access is needed.
- Run 40231578242: real pointer launcher click, null-sink volume scroll, favorites
  and local cover import passed. Closing management left keyboard focus on a
  hidden field, so search and game launch failed. Restored grid focus on close.
  Also retained image format before decoding (the SVG decoder cleared it after
  read), preserved cover aspect ratio, and supplied the tray fixture's own pixels.
- The local workspace reset on resume. Recovered the published source branch
  and reapplied the last uncommitted corrections. No M2 source was rebuilt.

Failed attempts are not full integration passes. Final accepted execution and
its tested commit are recorded in ci.json and status.md.
