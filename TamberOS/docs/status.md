# M1 live validation in progress · 2026-10-24

The previously missing QEMU tools now run from workspace-local extracted Ubuntu
packages. A real AlmaLinux 10.2 ARM64 VM booted and powered off cleanly. SSH login
and cloud-init completed in a subsequent VM. Direct guest DNS is blocked by the
execution environment; proxy networking and package/build verification are being
tested. The signed image CHECKSUM passes GPG verification against the AlmaLinux
10 fingerprint independently cross-checked on its official security page and
release notes. This does not yet mark all M1 gates complete.

GitHub CI is being prepared on a dedicated branch of GurnoorLog/Tamberbox at the
user's direction. The main branch will not be modified. The nine final concept
PNGs are still unavailable; the explicit asset gate reports that blocker.

The following report is the historical M1 baseline, retained until live validation
results are finalized:

# M1 verification report · 2026-10-23

**M1 is in progress, not complete.** Real VM tooling is implemented and the base
image is checksum-verified. QEMU execution is blocked by missing host tools.
No existing TamberBox installation was connected to, modified or flashed.

## Executed results

| Check | Result | Evidence |
|---|---|---|
| Starter baseline | PASS: 3 tests and structure check | Initial run before edits |
| Expanded offline suite | PASS: 20 tests | [offline-tests.txt](evidence/offline-tests.txt) |
| Required files and SVG parsing | PASS | Same transcript |
| Browser JavaScript syntax | PASS, `node --check prototype/app.js` | Invoked by `scripts/ci.sh`; exit 0 |
| Guest script shell syntax | PASS, `bash -n` | Invoked by `scripts/ci.sh`; exit 0 |
| Guest script refuses this host | PASS: exit 2 before probing/DNF | [guest-host-guard.txt](evidence/guest-host-guard.txt) |
| VM dry-run | PASS: argv generated without launching or creating a VM | Transcript plus no-side-effect test |
| Official image download/integrity | PASS: 478,937,088 bytes and matching SHA256 | [image-verification.json](evidence/image-verification.json) |
| Package/board source retrieval | PASS: pinned board source and official package listings observed | [source-observations.json](evidence/source-observations.json) |
| Brand/UI preservation | PASS: all supplied branding, prototype, shell and reference files byte-identical | [design-preservation.json](evidence/design-preservation.json) |
| Git changes | Isolated on `feature/m1-arm64-foundation`, starter on `main` | Git history in delivered bundle |

The tests exercise checksum corruption rejection, atomic download/caching with
mocked HTTP, partial-download preservation, path/symlink/device refusal, SSH
network defaults, cloud-init structure, existing-file protection, exact result
markers, board fixture detection and redaction. Mock HTTP tests are not VM tests.
The separately downloaded official image is real and was hashed in full.

## Blocked / unverified

- `qemu-system-aarch64`, `qemu-img`, `cloud-localds` and CMake are not available.
  Host: Ubuntu 24.04.3 x86_64. [Doctor output](evidence/host-tools.json).
- Workspace-scoped APT metadata retrieval failed with `setgroups`, `setegid` and
  `seteuid` permission errors. No dependencies were installed; no escalation was
  used. Firmware preparation, overlay creation and cloud-init execution are
  untested external-tool integrations.
- No boot, login, guest network, DNF transaction, package installation, Qt build,
  GUI rendering or RPM build occurred. No serial boot transcript exists.
- No GitHub remote or CI run exists. The workflow is configured, not proven.
- Checksum detached signature/key authentication remains unverified.
- QEMU/firmware binaries and RPM dependency snapshots are not globally pinned.
  The base image is pinned; byte-identical distro builds are not delivered.
- Board bootloader, exact kernel/config/modules, hardware I/O, accelerated GPU,
  Bluetooth/Wi-Fi and NPU remain unverified with AlmaLinux on the actual Ultra.
- No inference, gaming integration, compositor or real desktop session is added.

## Exact commands run

```sh
python3 -m unittest discover -s tests -v
python3 scripts/check_project.py
python3 scripts/qemu/vm.py doctor
python3 scripts/qemu/vm.py fetch
sh scripts/ci.sh
bash scripts/qemu/guest-check.sh  # expected refusal on this host, exit 2
```

`fetch` succeeded; `doctor` returned 1 for missing dependencies. Tests and syntax
checks returned 0. The guard test intentionally returned 2. Additional source
retrieval scripts used HTTPS GETs to URLs in the evidence manifest; they did not
execute downloaded board code. Design preservation was checked directly against
the supplied ZIP using Python zipfile and SHA256.

## Next narrow gate

On a disposable development host with prerequisites, execute the smoke VM recipe
in [the QEMU guide](../scripts/qemu/README.md), preserve `serial.log`,
`manifest.json` and `result.json`, then capture a separate real SSH login and Qt
compile transcript. Only then mark M1 complete. Keep M2 physical-board work on
hold until exact-board read-only inventory, asset licensing/checksums and a
separate test-media recovery plan exist.

## Rollback / delivery

Stop the VM before removing its ordinary `build/qemu/<name>` directory. No
physical disk operation is present. Source rollback is the starter `main`
commit or reverting the M1 commit. The ZIP includes source, evidence and a Git
bundle; no VM images, firmware, private keys or package caches are bundled.
Use `git clone TamberOS-history.bundle TamberOS-history` to restore the history.
