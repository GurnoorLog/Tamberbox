# M4 validation failure ledger

- Run 40323569803: native ARM64 compilation passed; graphical execution was gated by a stale Python source check expecting `showGames()` instead of the retained `showLibrary()` function. Updated that existing check. Alma four-target CTest passed.
- Run 40323881850: Python gates and both builds passed; QML engine rejected a component ID named `console`, which masks a global JavaScript property. Renamed it to `playMode`.
- Run 40324324033: M3 Waybar pointer/tray/audio, library artwork/favorites, game launch and CTest passed. Entering the new console produced a process segmentation fault before its first frame. Added GDB backtrace capture to the disposable test session; this run is not fullscreen evidence.

Final verified results, if achieved, are recorded separately in ci.json and status.md. Failed runs are never counted as successful graphical validation.
