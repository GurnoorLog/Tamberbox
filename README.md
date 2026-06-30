# TAMBERBOX — AI Laptop

**Orange Pi 5 Ultra · Armbian Noble · Hyprland · Local AI**

Built by [Praknoor (Gurnoor Tamber)](https://github.com/GurnoorLog)

A fully custom AI-powered laptop built on the Orange Pi 5 Ultra single-board computer. Every piece of software was hand-installed, compiled, and configured — nothing was pre-built.

---

## ✓ Achieved

| Feature | Detail |
|---------|--------|
| **OS** | Armbian Noble (Ubuntu 24.04) — Vendor kernel 6.1.115 |
| **WM** | Hyprland 0.47.0 — Compiled from source on ARM64 |
| **SDDM** | Dog Samurai login screen with animated video background |
| **Plymouth** | Custom Tamberbox boot splash — Cross HUD animation |
| **Local AI** | Ollama + qwen2.5:1.5b with custom Tamberbox personality |
| **Speech** | Whisper.cpp — Offline STT with ARM NEON optimizations |
| **NPU** | 6 TOPS — RKNN Toolkit2 verified working |
| **GUI** | Flask web interface with voice input, system stats, speak mode |
| **MOTD** | Sci-fi terminal banner with live system info |
| **Theming** | Pywal dynamic colors, mpvpaper live wallpaper |
| **Cursor** | Cinnamon cursor theme |

---

## Hardware Spec

| Component | Detail |
|-----------|--------|
| **SBC** | Orange Pi 5 Ultra |
| **CPU** | Rockchip RK3588 — 4× Cortex-A76 @ 2.4GHz + 4× Cortex-A55 @ 1.8GHz |
| **RAM** | 8GB LPDDR5 |
| **GPU** | Mali-G610 MP4 — Panthor driver (open source) |
| **NPU** | 6 TOPS — RKNN Toolkit2 — INT4/INT8/INT16/FP16 |
| **Storage** | microSD (boot) + M.2 NVMe PCIe 3.0 ×4 |
| **Network** | Wi-Fi 6E + Bluetooth 5.3 |
| **OS** | Armbian 26.2.1 Noble (Ubuntu 24.04 LTS) |
| **Kernel** | 6.1.115-vendor-rk35xx (Rockchip BSP) |

---

## Build Guide

See [`TAMBERBOX_COMPLETE_GUIDE.pdf`](./TAMBERBOX_COMPLETE_GUIDE.pdf) for the full 8-phase build journal including every error encountered and every fix applied.

### Quick Reference

```bash
# Launch Hyprland (from physical TTY)
Hyprland

# Tamberbox AI voice assistant
python3 ~/tamberbox-ai.py 'what is the orange pi 5 ultra'

# Web GUI
cd ~/TamberboxAI && python3 app.py &
chromium --no-sandbox --app=http://localhost:7777

# Check NPU
python3 -c "from rknnlite.api import RKNNLite; r=RKNNLite(); print('NPU OK')"

# Check GPU
ls /dev/dri/
dmesg | grep -i mali
```

---

## Key Challenges Solved

1. **Hyprland on ARM64** — No pre-built binary exists for Ubuntu Noble ARM64. Compiled all hyprwm deps from source in dependency order (hyprwayland-scanner → hyprutils → hyprlang → hyprcursor → hyprgraphics → aquamarine → Hyprland).

2. **SDDM video on ARM64** — First documented fix for animated video background on RK3588. Missing `libqt5multimedia5-plugins` package was the root cause.

3. **Plymouth on Armbian** — Armbian uses `armbianEnv.txt` (not GRUB). Required `verbosity=0` and `console=serial` to prevent kernel logs fighting Plymouth for display.

4. **GPU on RK3588** — Mali-G610 uses Panthor DRM driver. `/dev/mali0` does NOT exist — `/dev/dri/card*` and `renderD*` are the correct nodes.

---

## License

MIT — feel free to build on this work.

---

*"The machine obeys. The mind commands."*
