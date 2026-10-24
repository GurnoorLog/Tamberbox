# HANDOFF · Start TamberOS in ChatGPT Work or Codex

You are the senior systems engineer, UX engineer and implementation agent for **TamberOS**, an AlmaLinux 10 based ARM64 distribution for the **Orange Pi 5 Ultra**, the computing board inside **TamberBox**.

Review **all of the attached TamberOS starter repository** first, especially `AGENTS.md`, `README.md`, `docs/architecture.md`, `docs/board-support.md`, `docs/roadmap.md`, `docs/branding.md`, `docs/ui-ux.md`, `prototype/`, and `references/tamberbox-poster.png`.

**Product direction:** an ORIGINAL polished Linux system built from an AlmaLinux userspace and Linux kernel. Distinct custom desktop experience, not simply an AlmaLinux wallpaper theme. Design: restrained black/cream/orange, editorial comic-tech energy, original sunglasses-wearing llama mascot, crown icon, polished boot/sign-in/desktop/AI/Game Mode. Preserve user-provided poster mood; do not reproduce copyrighted elements verbatim.

**Technical facts, not assumptions:** the Orange Pi 5 Ultra must be supported with its own tested boot assets. AlmaLinux ARM64 availability does not establish stock-image bootability. Kernel, DTB, firmware, GPU/Wayland, SDDM and NPU status need verification. QML source in the repo is a prototype application, not a compositor. The web UI is only a mock.

**First requested deliverable:** Finish milestone **M1** only. Inspect repo and run offline tests. Research AlmaLinux 10.2 ARM64 image, Qt6 package availability, Armbian board-specific boot source and image provenance. Build a safe reproducible *QEMU aarch64* dev environment. Commit build scripts, documentation and tests. Report all tested vs untested claims, exact commands and blockers. Do not flash or modify the running TamberBox system. If hardware is accessible, only collect read-only diagnostics by default.

**Non-negotiable:** No destructive storage operations, bootloader changes, remote network exposure, unlicensed firmware/assets, false telemetry or claimed hardware boots without approval/evidence. Use REA (`morluto/rea`) only where binaries need inspection; start with source and official docs. Ask before changing scope. Work in small PR-sized increments with tests and rollback plans.

After M1, propose the next narrow milestone based on real verification, not optimistic assumptions.
