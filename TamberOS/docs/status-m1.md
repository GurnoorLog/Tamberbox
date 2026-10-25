# M1 verification report · 2026-10-24

**M1 development acceptance gates are complete.** A real AlmaLinux ARM64 QEMU
VM passed boot, SSH, cloud-init, HTTPS, DNF and package checks, installed the
toolchain, compiled the Qt/QML shell and powered off with QEMU exit code 0.
Native ARM64 GitHub CI also passed. No existing TamberBox
installation was connected to, modified, repartitioned or flashed. M2 is on hold.

## Verified results

| Check | Result | Evidence under `docs/evidence/m1-validation/` |
|---|---|---|
| Offline tests | 27 pass; project, asset, shell and JavaScript checks pass | `offline-final.txt` |
| Isolated tool bootstrap | Script executed successfully, download/extract only | `bootstrap-repeat.txt`, `host-packages.json` |
| Host tools | QEMU 8.2.2, qemu-img, cloud-localds, genisoimage; AAVMF 2024.02-2ubuntu0.9 with matching 64 MiB code/vars | Package manifest and VM manifest |
| Image authentication | Detached CHECKSUM signature and actual image SHA256 pass | `signature-verification.json` |
| Actual QEMU boot | AlmaLinux 10.2 aarch64, kernel 6.12.0-211.64.1.el10_2.aarch64; clean poweroff in final integrated smoke run | `live-real-07/serial.log`, `manifest.json`, `result.json` |
| SSH login | Generated-key authentication, strict host-key validation from local serial channel | `live-real-07/ssh-login.txt` |
| Cloud-init | Completed, no reported errors | `live-real-07/cloud-init.txt` |
| HTTPS transport | TLS verified through explicitly configured development proxy | `live-real-07/network-diagnostic.txt`, `guest-smoke.txt` |
| DNF transaction | 140 packages installed successfully inside the disposable VM | `live-real-07/dnf-install.txt`, `rpm-inventory.txt` |
| VM shell build | CMake reached 100%; executable identified as ARM aarch64 ELF | `live-real-07/shell-build.txt` |
| Integrated acceptance | All six gates true; QEMU exit 0 | `live-real-07/live-result.json`, `result.json` |
| GitHub Actions | Offline and native ARM64 AlmaLinux container jobs passed | `github-run2-offline.txt`, `github-run2-arm64.txt` |
| Qt/QML compilation | Real CMake compilation reached 100% in ARM64 CI | `github-run2-arm64.txt` |
| Original concepts | Nine screens, overview and README restored byte-for-byte from updated starter ZIP | `concept-provenance.json`, `final-concepts-gate.txt` |

The actual CI run is [40092069770](https://github.com/GurnoorLog/Tamberbox/actions/runs/40092069770),
for remote commit `c450f29263af4d84beac2a943353b3601246afb6`, on the user-approved
`feature/tamberos-m1-validation` branch. Main is unchanged. This refreshed run includes the mandatory restored-asset gate and current
implementation; its full job logs and structured job results are archived.

## Failures and limitations

- Initial smoke VM booted and powered off, but guest DNS/network/DNF/package
  checks failed. Its `result.json` correctly reports failure, not a passed smoke.
- Run `live-real-06` passed identity and HTTPS, then was interrupted during DNF
  metadata processing. It did not produce a final VM result. Its partial output
  cannot establish a passed DNF transaction. Fresh run `live-real-07` subsequently completed all gates successfully.
- Direct guest DNS is not working in this sandbox. Proxy-assisted HTTPS does not
  establish direct networking. The explicit public host CA bundle is installed
  only in the disposable guest; TLS verification is not disabled.
- Shell compilation is verified both inside QEMU and in native ARM64 AlmaLinux
  CI. No graphical session, rendering, Wayland compositor or RPM package build
  has been validated. The VM uses non-secure AAVMF; Secure Boot is untested.
- `result.json` is the low-level boot/smoke result and deliberately leaves login
  unverified. The separate `live-result.json` and real `ssh-login.txt` establish
  SSH login; the low-level file alone cannot make that claim.
- Exact Orange Pi 5 Ultra bootloader, kernel, DTB and driver requirements are
  researched in `board-support.md` and `feasibility-matrix.md`. No physical-board
  boot or AlmaLinux GPU/NPU, Wi-Fi/Bluetooth, audio or storage compatibility is
  claimed. Hardware bring-up has not begun.
- The base image and Ubuntu snapshot are pinned. RPM repositories and CI container
  tags still move; this is a repeatable development recipe, not a bit-identical
  distribution build or complete dependency lock.
- Key fingerprint `EE6DB7B98F5BF5EDD9DA0DE5DEE5C11CC2A1E572` was cross-checked on
  the official AlmaLinux security page and 10.0 release notes, separately from the
  image endpoint. This is HTTPS-based independent source authentication, not an
  out-of-band human signing-key attestation.

## Reproduction and rollback

See `scripts/qemu/README.md` for exact commands. The executed live command uses
`validate_live.py --name live-real-07 --use-host-proxy --host-ca-bundle
/etc/ssl/certs/ca-certificates.crt --build-shell`, with matching local AAVMF paths.
Offline checks: `sh scripts/ci.sh`. Signature check: `python3
scripts/qemu/verify_signature.py --image <the pinned qcow2>`.

Original branding and concept bytes are protected by `references/assets.lock.json`.
The sunglasses-llama `01-bootloader-concept.png` is the official future boot
reference. The requested macOS-like desktop direction is documented separately
in `desktop-direction.md`; WhiteSur installers were not run.

Source changes are isolated on feature branches. Revert those commits to roll
back code. Stop QEMU before deleting only its named disposable directory. The
archive excludes VM disks, firmware, private keys and seeds; it includes source,
evidence and a Git bundle. Restore history with
`git clone TamberOS-history.bundle TamberOS-history`.
