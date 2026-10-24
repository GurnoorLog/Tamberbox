# TamberOS product vision

## Positioning
A **private-first edge-AI desktop OS** for a portable Orange Pi 5 Ultra computer: polished enough for everyday use, open enough for deep tinkering. We reuse Linux/AlmaLinux; the original contribution is the end-to-end integration, branded UX and platform services.

## Principles
1. **Distinct, not overloaded:** serious productivity interface with comic-book bursts, not a poster pasted on every screen.
2. **Local by default:** visibly label offline AI availability; user opts into downloads and web features.
3. **Honest hardware UX:** unavailable features appear disabled with reasons and next steps.
4. **Fast on ARM:** minimal idle CPU/RAM; composition measured on the actual board.
5. **Accessible:** keyboard-first, scalable text and optional reduced motion.
6. **Recoverable:** updates/boot experiments cannot strand the only working drive.

## Target user journeys
- Turn on TamberBox → branded splash → clean sign-in → desktop in a measured time budget.
- Open Tamber AI → select installed model → chat privately → see whether backend is available.
- Enter Game Mode → controller-friendly navigation → launch a locally installed title → return to Desktop.
- See thermals/storage/CPU without an admin password; understand NPU availability without misleading graphs.
- Update user applications safely; recover if a system update fails.

## Non-goals for V1
- Writing a new Linux kernel, U-Boot or proprietary GPU/NPU driver.
- Shipping copyrighted games/ROMs or third-party system themes.
- Claiming native NPU integration until an actual model is demonstrated.
- A giant unreviewed agent generated code dump.
