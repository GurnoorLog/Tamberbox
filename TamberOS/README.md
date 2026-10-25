# TamberOS

**An original, AlmaLinux-based ARM64 experience for TamberBox.**

> Status: **M1 complete; M2 hardware acceptance pending**. A real AlmaLinux ARM64 image candidate builds and passes offline validation. The functional Qt/QML session prototype passes ARM64 X11 tests. Neither has been verified on the Orange Pi 5 Ultra.

TamberOS combines a Linux kernel, an AlmaLinux userspace, and new Tamber-specific user-facing software. The hardware target is the **Orange Pi 5 Ultra (RK3588, aarch64)**. The visual direction comes from the accompanying TamberBox poster: ink-black backgrounds, electric orange details, warm cream typography, restrained comic-book energy and an **original sunglasses-wearing llama mascot**.

## Experience

- **Desktop** — launch apps, search, switch modes, manage files and devices.
- **AI Studio** — private-first local chat powered by Ollama *when installed and configured*; model state must be real, never invented.
- **Game Mode** — keyboard/controller-oriented library and launcher with locally installed games or properly licensed emulators.
- **System Center** — thermals, CPU, RAM, storage and validated NPU capability indicators.
- **Boot / sign-in** — consistent Tamber identity across U-Boot where technically feasible, Plymouth, and an SDDM theme after package compatibility is verified.

## What is built here

| Component | Status |
|---|---|
| Product/technical documentation | Complete initial draft |
| Brand palette, original SVG mascot + crown | Included |
| Clickable multipage UI mock | Included; **mock data only** |
| Qt 6/QML desktop application scaffold | Real app launching and keyboard tests pass in ARM64 AlmaLinux/X11 CI |
| Safe read-only hardware telemetry CLI | Implemented with unit tests |
| System image | Built and validated offline; hardware boot pending |
| RPM packaging and NPU integration | Not implemented |
| Boot verified on Orange Pi 5 Ultra | **Not verified** |

## Open the interactive UI concept

Open [`prototype/index.html`](prototype/index.html) locally in a modern browser. The demo does not install anything, modify the machine or communicate with Ollama. Switch between Home, AI, Games, System, Settings, Sign-in and Boot using its navigation.

## M1 implementation update · 2026-10-24

The signed AlmaLinux 10.2 image boots under workspace-local QEMU/AAVMF. Real
SSH, cloud-init, smoke checks and DNF installation pass. The Qt/QML shell compiled
both inside QEMU and in native ARM64 GitHub CI. M1 development gates are complete;
physical board support and graphical runtime remain unverified.
The nine original screen concepts and overview are restored byte-for-byte,
with a mandatory preservation check. The sunglasses-llama bootloader concept is
the official future boot reference, not a demonstrated bootloader implementation.

See the exact acceptance state and remaining limitations in
[`M1 results`](docs/status-m1.md), the runnable
[`QEMU guide`](scripts/qemu/README.md), and
[`engineering decisions`](docs/decisions-m1.md). No existing TamberBox
installation was connected to, modified or flashed.

## Development quick start

```bash
python3 -m unittest discover -s tests -v
python3 scripts/check_project.py
```

Run the read-only hardware telemetry sample on a Linux host:

```bash
python3 services/tamber-hardware/tamber_hardware.py --json
```

**Qt demo** (only on a development machine with Qt 6 Quick/QML and CMake installed):

```bash
cmake -S shell/tamber-shell -B build/shell
cmake --build build/shell
./build/shell/tamber-shell
```

This is a functional session prototype running inside an existing window manager/compositor, **not yet a standalone Wayland compositor or fully functioning desktop environment**.

## Roadmap: smallest trustworthy vertical slice

1. Develop and test UI and services on a non-critical Linux development machine or VM.
2. Bring up a verified AlmaLinux aarch64 userspace using an official AlmaLinux image in QEMU.
3. Capture exact Orange Pi 5 Ultra boot requirements from known-good board-specific software.
4. Boot a working Linux kernel + **AlmaLinux rootfs** on a separate test SD card with serial-console evidence and rollback.
5. Establish network, GPU display acceleration, audio, storage and input; only then pursue custom full-session integration.
6. Package original Tamber components into RPMs, build a reproducible image, and implement safe updates.

Read [`docs/architecture.md`](docs/architecture.md), [`docs/roadmap.md`](docs/roadmap.md), [`docs/ui-ux.md`](docs/ui-ux.md) and [`docs/board-support.md`](docs/board-support.md).

## Codex and ChatGPT Work

See [`prompts/00_WORK_HANDOFF.md`](prompts/00_WORK_HANDOFF.md) for a reusable project handoff and [`prompts/README.md`](prompts/README.md) for an ordered implementation sequence. [`AGENTS.md`](AGENTS.md) defines scope, constraints, safety and verification for Codex.

## Security, licensing and trademark notes

- Preserve upstream licenses and attribution. Custom theme assets and the third-party poster are **not** asserted to be under an open-source license.
- Do not redistribute vendor firmware, GPU/NPU runtimes or boot components without checking redistribution conditions.
- The Tamber llama is intended as an **original mascot**, not the Ollama project's official logo or an implied partnership.
- Never run downloaded reverse-engineering tooling against untrusted programs with elevated privileges. REA is optional and intended for evidence-based analysis where source is unavailable, not a prerequisite to ordinary open-source development.
- No flashing, repartitioning, bootloader replacement or privileged host mutation is performed by this repository.

## Project status

**2026-10-23** — foundation kit authored. Native ARM64 QML compilation is now verified; RPM packaging, actual board boot and driver support remain unverified.

## M2 development delivery

See [verified results and limitations](docs/status.md), [exact boot chain](docs/m2-boot-chain.md), [separate-card build/testing procedure](docs/m2-hardware-testing.md), and [shell instructions](shell/tamber-shell/README.md). No physical storage has been written.
