# M4 validation failure ledger

- Run 40323569803: native ARM64 compilation passed; graphical execution was gated by a stale Python source check expecting `showGames()` instead of the retained `showLibrary()` function. Updated that existing check. Alma four-target CTest passed.
- Run 40323881850: Python gates and both builds passed; QML engine rejected a component ID named `console`, which masks a global JavaScript property. Renamed it to `playMode`.
- Run 40324324033: M3 Waybar pointer/tray/audio, library artwork/favorites, game launch and CTest passed. Entering the new console produced a process segmentation fault before its first frame. Added GDB backtrace capture to the disposable test session; this run is not fullscreen evidence.

Final verified results, if achieved, are recorded separately in ci.json and status.md. Failed runs are never counted as successful graphical validation.

- Run 40325026392 captured the crash inside Qt Quick Layouts. The action row had a reactive JavaScript array model. Keeping its four delegates stable and changing their labels eliminated the observed crash on the same runner/Qt version.
- Run 40325658935 then rendered the console, navigated, launched a fullscreen game, returned on game close and launched an app. It failed at a test expecting two Esc presses to exit despite open details/search. The explicit mode shortcut is the guaranteed exit from any navigation depth; the test was corrected to exercise it. Hierarchical Esc is also tested from System through Home to Desktop.
- Final run 40325938997 passed both native ARM64 jobs and every graphical assertion. Existing checks run 40325939248 also passed. Final evidence is under runtime/ and alma/.
