# Codex / ChatGPT Work prompt pack

**Start with [`00_WORK_HANDOFF.md`](00_WORK_HANDOFF.md).** Then send one milestone prompt at a time; confirm test evidence before moving on. Do not paste all prompts as a single uncontrolled implementation request.

| File | Purpose |
|---|---|
| `00_WORK_HANDOFF.md` | Overall reusable mission and guardrails |
| `01_RESEARCH_ARM64.md` | Check actual AlmaLinux/toolchain/board compatibility |
| `02_QEMU_FOUNDATION.md` | Reproducible safe AlmaLinux aarch64 development environment |
| `03_QML_SHELL.md` | Evolve the initial shell into working UI |
| `04_BRAND_BOOT.md` | Original Plymouth + sign-in theme, feasibility gated |
| `05_LOCAL_AI.md` | Local Ollama adapter and safe UX |
| `06_GAMING.md` | Game Mode launcher and controller navigation |
| `07_PACKAGING.md` | RPM metadata and reproducible image engineering |
| `08_RELEASE_REVIEW.md` | Evidence-driven quality gate and release notes |

Each agent should respect `AGENTS.md`, keep work on a branch, run project tests and summarize what was actually built versus merely specified.
