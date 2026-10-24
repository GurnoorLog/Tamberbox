# M1 decisions and rollback — 2026-10-23

1. **Separate VM and board gates.** QEMU `virt-8.2` with `neoverse-n1` under TCG
   is a userspace development target; it does not simulate the RK3588 board.
   Reference: https://www.qemu.org/docs/master/system/arm/virt.html.
2. **Lock the base, isolate writes.** Official dated image and SHA256 are pinned.
   Use a fresh qcow2 overlay and copied AAVMF variables per VM. Never reference
   `/dev` storage, mount host folders or install to TamberBox. Rollback: stop the
   VM and remove only its named build directory.
3. **Explicit lifecycle.** Downloads and VM starts require separate commands;
   dry-run creates nothing. QEMU has no monitor and no default forwarded ports.
   Login is generated-key-only, opt-in loopback SSH. Reference for seed structure:
   https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html.
4. **Do not hide failed gates.** Preserve serial output, report timeout/failure,
   require distinct guest PASS markers, keep login explicitly unverified until a
   real session exists. Package listings are not successful installs.
5. **Retain design.** Branding, poster, prototype and Qt shell source are unchanged.
   M1 adds infrastructure, source evidence and tests only.
6. **No binary redistribution.** Downloaded Alma image stays in ignored local
   build cache. No image/firmware/vendor runtime is in the deliverable. SHA256
   integrity was checked; PGP authentication remains open.
7. **CI scope is explicit.** Add offline checks and an ARM64 AlmaLinux container
   compile job. No upstream CI run happened here. Container digest and RPM NEVRAs
   need locking before claims of bit-identical build reproducibility.
8. **Avoid privilege workarounds.** Workspace-scoped APT metadata retrieval failed
   with setgroups/seteuid permission errors. No host dependency installation or
   escalation was attempted. Continue with tested offline code and identify the
   missing QEMU tools instead of pretending the VM ran.

Source rollback: changes are isolated on `feature/m1-arm64-foundation`; the
original starter is the `main` commit. Revert the M1 commit to undo source changes.
The packaged kit includes a Git bundle preserving both commits. There is no
remote push/publication, since the code/artwork redistribution policy is still
undecided. Private logs/keys, downloaded images and host package cache are excluded.
