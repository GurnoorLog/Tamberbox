# Tamber Waybar V2.a adaptation

Visual inspiration: [HANCORE-linux/waybar-themes V2.a](https://github.com/HANCORE-linux/waybar-themes/tree/main/config/V2.a) (MIT). This is an adapted, standalone configuration, **not** a replacement for the upstream theme files. See upstream for copyright and license details.

Differences: Sway rather than Hyprland workspace/window modules; removed Omarchy-only commands, pacman update checks, `wttrbar` weather and missing CSS import; TamberOS launcher invokes the existing IPC interface. Hardware modules may display unavailable states; battery is deliberately omitted on this SBC.

Start via `session/start-tamber-session`, which automatically selects the external bar when Waybar is installed. No files are written to ~/.config/waybar. To revert use `TAMBER_USE_WAYBAR=0 session/start-tamber-session`. Do not use `omarchy-restart-waybar` on AlmaLinux/Sway. Standard `swaymsg reload` reloads compositor config, not Waybar CSS; terminate and restart only this session's Waybar process to reload.
