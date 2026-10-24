# TamberOS agent instructions (Codex / Work)

## Mission
Create a high-quality ARM64 AlmaLinux-derived distribution for the Orange Pi **5 Ultra**, centered on an original Tamber Shell, private-first AI and gaming UI. Treat the supplied TamberBox visual reference as a direction, not as a pixel-perfect requirement.

## Hard constraints
1. **Never claim boot/hardware compatibility without test evidence.** The exact board is **Orange Pi 5 Ultra**, not Orange Pi 5, 5 Plus or 5 Max.
2. **Never flash disks, repartition, edit bootloader locations, or change real-machine firmware without explicit user approval, backup instructions and the exact device check.** Default to read-only inspection, VM and disposable artifacts.
3. Prioritize a **working kernel + AlmaLinux ARM64 rootfs** before proposing a replace-all-custom compositor solution.
4. Keep proprietary and vendor binaries out of the repository until licenses and checksums are reviewed.
5. For Ollama, GPU and NPU, distinguish demonstrated capability from roadmap. Never fabricate live telemetry, connected models or inference benchmarks.
6. Use original branding. Do not repackage Ollama's logo or imply affiliation.
7. Protect local files: no blanket filesystem read, network exposure or agent shell access without explicit user permission; AI features are opt-in.
8. Keep the UI accessible at 1280x720, keyboard navigable and usable without animations.
9. REA (`morluto/rea`) is *optional*: use source code and documentation first, then licensed, bounded local analysis if a claim depends on behavior absent from source. REA installation is **not** performed automatically.
10. For each change: provide source, a runnable check/test, limitations and a clear rollback note.

## Branch strategy
- `main`: reviewed, tests passing, no destructive scripts.
- `feature/<component>`: focused implementation; small PRs.
- `experimental/board-bringup`: only disposable images and diagnostics.

## Code conventions
- `shell/`: Qt6/QML (C++ for entrypoint), production Wayland integration only after proof of viability.
- `services/`: Python initially; least-privilege and no silent background network requests.
- `packaging/`: explicit RPM specifications, source and license manifests, pinned versions/checksums.
- `tests/`: runnable offline smoke tests.
- `prototype/`: browser-only, mock data and interaction design reference.

## First actions
Read `README.md`, `docs/architecture.md`, `docs/board-support.md`, `docs/ui-ux.md`, `docs/roadmap.md`; run `python3 -m unittest discover -s tests -v` and `python3 scripts/check_project.py`. Then implement the **next unchecked item** in the milestone tracker, starting with reproducible ARM64 AlmaLinux QEMU bring-up. Do not redesign the project's goals without documenting tradeoffs.
