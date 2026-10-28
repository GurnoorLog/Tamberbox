# Amber desktop refinement

Original implementation within the existing Qt/QML shell and Sway session. No external shell code, shaders, icons or artwork were imported. Visual direction: floating panel islands, warm charcoal surfaces, cream typography, restrained orange focus states, rounded dock and grouped controls. Wallpaper is unchanged. Existing game-library and fullscreen-console functionality are retained.

Implemented: independent Waybar island groups with orange active workspace pills; unified QML control, slider, launcher and settings palette; higher-contrast search field; 60px application rows; rounded dock; panel entrance opacity transitions respecting the reduced-motion preference; matching focused/unfocused Sway window chrome. All existing launch and service actions remain connected to their backends.

Validation: local 35 offline tests and project check pass. ARM64 compilation and headless Wayland interaction are running in GitHub Actions; see the latest branch workflow results. Previous screenshots do not represent this revision. No physical device testing has occurred.

Not implemented: audio-reactive dock, DMA-BUF visualiser integration, GPU blur, curved compositor window clipping, new notification service or hardware telemetry panels. Decorative graphs are not used to suggest those features exist. A future audio visualiser needs real PipeWire capture, bounded rendering, and GPU validation before integration.

Rollback: restore the previous desktop QML, session/sway.conf and session/waybar files from commit e984209. User settings and existing OS storage are untouched.
