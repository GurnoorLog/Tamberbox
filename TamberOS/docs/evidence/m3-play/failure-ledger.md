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

- Run 40274961568: real 2048 launch succeeded. The old compositor test assumed
  one window and timed out after a second window opened. Changed it to track the
  isolated terminal by ID and verify the other window survives. Cleaned up only
  the document portal's FUSE mount inside the test's private runtime directory.
- Run 40275382120: tray activation and workspace clicks passed. The game became
  visible just after the fixed two-second check, causing a false-negative launch
  assertion. Replaced the sleep with a bounded query for its exact Wayland app ID.
  Success evidence is now written only after teardown and temporary cleanup.

Final run 40275789046 and existing checks 40275789047 pass at commit
4f07a72256d1971bb4595d343adc4a8a82db65fb. Evidence under runtime/ and alma/
is from that passing run, not an earlier attempt.
