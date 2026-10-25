# TamberOS status · M3 development

M1 remains complete. M2 physical hardware validation is pending; its candidate
and image scripts are preserved unchanged. M3 is developed remotely using
virtual desktops, independently of physical board access.

See [M3 architecture and test instructions](m3-desktop.md),
[M2 evidence](status-m2.md) and [hardware testing procedure](m2-hardware-testing.md).

The desktop now implements a Sway session, Qt layer-shell wallpaper/panels/dock,
application search/launch, window focus/minimize/fullscreen/close integration,
persistent appearance settings, and service-backed audio/network requests.
Login and boot themes are implemented and staged separately. Final runtime
results and CI provenance will be recorded in the development delivery evidence.
