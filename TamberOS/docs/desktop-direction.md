# Desktop direction · 2026-10-24

The user selected a macOS-like desktop direction, with
[WhiteSur GTK](https://github.com/vinceliuice/WhiteSur-gtk-theme) as a reference.
This updates the future M3 desktop layout, not the official boot experience.

## Decisions

- Slim top bar with Tamber identity, active application and honest system status.
- Centered floating dock with keyboard focus, accessible labels and app indicators.
- Rounded application windows, quieter spacing, clear typography and restrained
  translucent surfaces. Provide opaque and reduced-motion modes.
- Retain ink-black, warm cream and orange accents; retain the original sunglasses
  llama and crown. Avoid replacing them with Apple branding or generic icons.
- Keep the original nine concept PNGs unchanged as historical visual references.
  `01-bootloader-concept.png` remains the official boot reference.
- Build desktop interactions in the existing Qt6/QML architecture after M1.
  GTK theme installation cannot theme Qt Quick controls or create a compositor.

## Reference assessment

Read upstream README.md (blob 6613e97182c481de4f89aeae1ce03cd813f83066)
and COPYING (blob 10a35e6a96d62a23a998b5fdfa4532abae0bf2be) through GitHub.
The README describes GTK themes, GNOME extensions and optional GDM/Firefox
modifications; COPYING contains an MIT-style permission grant requiring notice
retention. No upstream theme code, imagery or installer has been copied or run.
If code is adopted later, review the specific files and retain their notices.

M1 remains focused on validation. This is a recorded design decision, not a claim
that a macOS-like desktop, dock, blur or GTK integration has been implemented.
Rollback: revert this direction document; original assets and shell are intact.
