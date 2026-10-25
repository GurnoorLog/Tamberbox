# M3 failure and correction record

- Initial Wayland run 40185156873 compiled but sent input before desktop frames.
  Added readiness markers emitted after rendered frames.
- Run 40206032507 rendered the shell but lost early virtual-keyboard input.
  Waited for the virtual keyboard to initialize before typing/Return.
- AlmaLinux run 40206132308 exposed Qt 6.10's separate private CMake module.
  Added explicit private-module discovery.
- AlmaLinux run 40206384365 exposed a removed Qt private handleExpose API.
  Applied the exposure version split used by upstream LayerShellQt v6.5.0.
- Screenshot/log review of 40206820248 found an invalid QIcon resource URL and
  clipping when the old layer-shell surface's dock width changed. Used the Qt
  resource path syntax and a stable transparent layer surface with a centered
  content-sized dock. Added runtime image-error rejection.

Failures were fixed in source and followed by real CI reruns. No mocked output
was substituted for compositor or native build evidence.
