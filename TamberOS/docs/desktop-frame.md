# UI-only frame refinement

Implemented narrow edge frame with rounded inner corners, compact dark top tabs, orange workspace focus, compact status symbols, and dock reveal on hover. Wallpaper remains unchanged. Rollback: restore Desktop.qml and session/waybar from 556ec1d.

Actual screenshot: evidence/ui-frame/desktop.png. ARM64 source compiled and Sway/grim captured it in workflow 40770930384. No test suite was run. The screenshot job subsequently failed during temporary-directory cleanup because the desktop portal mounted runtime/doc; the screenshot itself completed. Capture helper now leaves its isolated temporary runtime to disposable-runner teardown instead of traversing a live portal mount. This cleanup-only change was not rerun. UI rendering is evidenced; broader regression and hardware validation are not claimed.
