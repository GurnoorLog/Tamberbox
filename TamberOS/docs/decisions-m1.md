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

## Validation update · 2026-10-24

The entries above describe the original baseline. They are superseded where
new evidence exists:

- Workspace-local extraction from signed Ubuntu snapshot packages provides QEMU,
  qemu-img, cloud-localds and matching AAVMF without host package installation.
  The bootstrap script itself was executed successfully on the repeat run.
- The AlmaLinux CHECKSUM signature is now verified; the primary key fingerprint
  was cross-checked on official security and release-note pages independently
  of the image endpoint. Trust scope is documented in the signature evidence.
- Real QEMU boots, cloud-init and SSH now have transcripts. Direct guest DNS is
  unavailable here; explicit host proxy transport with verified TLS is tested
  separately. A passed network request alone is not a passed DNF transaction.
- Native ARM64 AlmaLinux GitHub Actions compiled the shell successfully. The user
  authorized the dedicated `feature/tamberos-m1-validation` branch in
  GurnoorLog/Tamberbox. Its main branch and existing installation are untouched.
- Nine final concepts plus overview and README were restored exactly from updated
  starter-kit version 2. CI now requires their hashes. The official boot reference
  is the original sunglasses-llama image, not a generic theme.
- The requested WhiteSur-inspired desktop layout is recorded in
  [desktop-direction.md](desktop-direction.md), for M3 after M1 validation.

Revert feature-branch commits to roll back source changes. Delete only stopped,
explicitly named disposable VM directories to roll back guest writes. Do not
remove caches/VMs while QEMU is running. No firmware or image binaries, private
SSH keys or cloud-init seed images are included in source delivery.

Final acceptance: `live-real-07` passed all four smoke markers, SSH, cloud-init,
a 140-package DNF transaction and a Qt/QML compilation to ARM aarch64 ELF, then
powered off cleanly (QEMU exit 0). M1 development acceptance is complete within
the stated proxy and reproducibility boundaries. Hardware bring-up stays on hold.
