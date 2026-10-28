# Compact bar and optional GPU surfaces

The reference image calls for a 28px dark edge bar with small workspace dots and a compact clock, rather than large floating islands. This revision implements that original layout in Waybar, retaining the orange active state, tray, audio and network modules. Dots select the same numbered Sway workspaces; the pointer test selects the second visible workspace and checks Sway's actual state.

The optional `shell/tamber-surfaces/shell.qml` is an original auxiliary panel that consumes a real exported DMA-BUF through the custom shell runtime. It creates no second bar, no fake telemetry and no simulated visualiser. It does not replace the working Tamber Qt desktop. Missing frames produce an explicit disconnected message. Rendering is capped at 24fps; set TAMBER_REDUCED_MOTION=1 before launching to stop updates. Hiding/closing the panel stops its rendering. The export producer must be stopped separately.

## Experimental GPU test

Dependency revisions are pinned in `packaging/visuals/sources.json`. Build the pinned custom Quickshell and visualiser in an isolated prefix using their upstream build instructions and retain their license files. The runtime requires Qt >=6.6 (QQuickRhiItem itself requires an appropriate newer Qt), EGL/OpenGL, Wayland and the upstream build dependencies. The current Qt6.4 desktop build cannot load this optional module. This is a separate executable and does not change the normal desktop's Qt requirement.

Start the visualiser using an upstream export-enabled configuration, on the same GPU as the surface consumer. Audio capture is explicit and opt-in: this project does not start a capture process. Then, inside a GPU-rendered disposable Wayland session:

```
python3 scripts/run_gpu_surface.py --binary /absolute/prefix/bin/quickshell --socket /absolute/path/to/export.sock --dry-run
python3 scripts/run_gpu_surface.py --binary /absolute/prefix/bin/quickshell --socket /absolute/path/to/export.sock
```

The wrapper requires a same-user socket and refuses symlinks, regular files and the software backend. Dry-run validates the launch prerequisites only, not the DMA-BUF protocol or GPU. The custom runtime reports missing QML types; passing an upstream binary without the custom item is unsupported. No automatic startup or modification of user configuration occurs.

GPU acceptance still pending: compile the custom runtime, load the QML item, display real audio-reactive frames, verify resize/fractional scaling, fd lifetime across disconnect/restart, same-GPU import and frame pacing. The upstream protocol currently lacks explicit synchronization and reconnect support; restart the consumer after restarting the exporter. Test both processes with fd monitoring before enabling long sessions. NVIDIA/Intel demonstration results do not verify RK3588.

Offline tests validate launcher guards. Real ARM64 CI validates only the existing desktop and compact bar, not this GPU sidecar. No GPU render node or local Qt toolchain is available in this workspace. Do not label the optional integration GPU-validated.

Rollback: restore session/waybar, Session.cpp and the session test from commit 1e7d792. The optional sidecar can simply remain unlaunched; nothing is installed into an existing OS.
