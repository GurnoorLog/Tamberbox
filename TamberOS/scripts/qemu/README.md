# AlmaLinux ARM64 development VM — M1

Real AlmaLinux ARM64 boot, SSH login and cloud-init have been demonstrated.
See [the dated results](../../docs/status.md) for package and build acceptance. This uses QEMU's
virtual ARM platform, not an emulated Orange Pi. Never pass a physical device.

## Host prerequisites

Use a disposable Linux development machine, not the existing TamberBox. Required:
Python 3.11+, QEMU 8.2+ (`qemu-system-aarch64`, `qemu-img`), cloud-image-utils
(`cloud-localds` with its ISO-generation dependency), OpenSSH `ssh-keygen`, and
matching AAVMF UEFI code/variable templates. On Debian/Ubuntu the relevant package
names are `qemu-system-arm qemu-utils qemu-efi-aarch64 cloud-image-utils`.
Install these through your development host's package manager, or use the
workspace-only bootstrap below. The project does not install host packages. Run from the repository root:

```sh
python3 scripts/qemu/vm.py doctor
sh scripts/ci.sh
python3 scripts/qemu/vm.py fetch --dry-run
python3 scripts/qemu/vm.py fetch
```

`fetch` is the explicit network operation. It downloads the dated official image,
checks its SHA256 against `image.lock.json`, then makes the cached file read-only.
No `latest` aliases. Failed downloads cannot become a usable base image. The detached checksum signature is verified before preparation using the
included AlmaLinux 10 public key. Its primary fingerprint was independently
cross-checked against the official security page and 10.0 release notes, separate
from the image download endpoint. See `trust/` and `verify_signature.py`; this is
official HTTPS authentication, not an out-of-band human key attestation.

## Prepare and execute a smoke VM

Resolve the firmware symlinks to real files; paths depend on the host package.
The example is the Debian/Ubuntu AAVMF layout. Both must be matching 64 MiB pflash
files from the same firmware package. AAVMF 2024.02-2ubuntu0.9 with QEMU 8.2.2
was used for the real boots recorded in the evidence.

```sh
python3 scripts/qemu/vm.py prepare --name smoke01 --smoke \
  --code "$(readlink -f /usr/share/AAVMF/AAVMF_CODE.fd)" \
  --vars "$(readlink -f /usr/share/AAVMF/AAVMF_VARS.fd)"
python3 scripts/qemu/vm.py run --name smoke01 --network --timeout 1800 --dry-run
python3 scripts/qemu/vm.py run --name smoke01 --network --timeout 1800
```

Preparation does not boot. It copies firmware, generates a new Ed25519 key,
creates a NoCloud seed and a 20 GiB sparse qcow2 overlay. The verified base is
never the writable VM disk. Only files inside `build/qemu/` are output. Existing
VM directories are refused, including after an interrupted prepare. Use a new
name or remove only the failed VM directory after reviewing it.

The smoke guest emits OS/kernel identity, DNS/HTTPS connectivity, DNF cache and
package-availability results, plus installed RPM versions, to `serial.log`, then
powers off. `result.json` requires all four exact PASS markers and a clean QEMU
exit. A timeout is failure, not a boot success. Real guest execution is recorded in the dated report; failed network
attempts are retained as failures. `--network` explicitly enables outbound guest traffic; no inbound forwarding
is added. Without it QEMU restricts user networking and online smoke checks fail.
The QEMU monitor is disabled, with no host shares or device passthrough.

## Login and shell compilation (separate acceptance evidence)

Prepare a second VM without `--smoke`, using the same firmware arguments. Start:

```sh
python3 scripts/qemu/vm.py run --name dev01 --network --ssh-port 2222 --timeout 7200
```

From a second terminal, after SSH is ready:

```sh
ssh -i build/qemu/dev01/id_ed25519 -p 2222 \
  -o UserKnownHostsFile=build/qemu/dev01/known_hosts tamber@127.0.0.1
```

Verify the initial host-key fingerprint against the serial console output before
accepting it. There is no root/default password; root SSH and password SSH are
disabled. The per-VM user has passwordless sudo **inside the disposable guest**.
No private key belongs in Git or a shared archive.

Inside that guest, collect `uname -m`, `uname -r`, `/etc/os-release`,
`cloud-init status --long`, and run `sudo /usr/local/bin/tamber-m1-check`. Copy the
source tree into the guest using scp (exclude build, .git and secrets). Install
only into this throwaway guest:

```sh
sudo dnf --releasever=10.2 install gcc-c++ cmake ninja-build \
  qt6-qtbase-devel qt6-qtdeclarative-devel rpm-build
cmake -S shell/tamber-shell -B build/shell -DCMAKE_BUILD_TYPE=Release
cmake --build build/shell --parallel 2
rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort > build/rpm-inventory.txt
sudo poweroff
```

Native ARM64 AlmaLinux CI compiled the source successfully. Consult the dated
report for the separate QEMU installation/compilation outcome. A window or
Wayland session is a later gate. Source compilation is not a graphical smoke test.
The dev run will not report overall PASS merely because someone logged in; keep
an actual login transcript separately. Current run logs are single-use: prepare
a fresh VM to repeat a smoke test, preserving previous evidence.

## Isolated tools and automated live validation

On an Ubuntu 24.04 x86_64 development host:

```sh
python3 scripts/qemu/bootstrap_host.py --download
export PATH="$PWD/build/isolated-host/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="$PWD/build/isolated-host/root/usr/lib/x86_64-linux-gnu"
python3 scripts/qemu/verify_signature.py --image build/qemu/cache/AlmaLinux-10-GenericCloud-10.2-20261012.0.aarch64.qcow2
python3 scripts/qemu/validate_live.py --name live01 \
  --code "$PWD/build/isolated-host/root/usr/share/AAVMF/AAVMF_CODE.no-secboot.fd" \
  --vars "$PWD/build/isolated-host/root/usr/share/AAVMF/AAVMF_VARS.fd" \
  --build-shell
```

The bootstrap downloads signed packages from the dated Ubuntu snapshot and
extracts them under `build/isolated-host`; it never invokes package installation
or maintainer scripts. It reuses libraries already present on the host, so its
package inventory is not a complete portable host root filesystem.

In a development sandbox with a credential-free loopback HTTP proxy, add
`--use-host-proxy`. If that proxy requires a private development CA, explicitly
provide its public PEM bundle with `--host-ca-bundle PATH`. Only the disposable
guest receives that trust anchor; HTTPS certificate verification remains on.
Proxy transport does not verify direct guest DNS or unrestricted networking.
Do not add proxy credentials or private keys to the seed or evidence.

The live validator starts QEMU and SSH within one network namespace, obtains the
SSH host key from the local serial transcript, verifies it strictly, and records
SSH, cloud-init, smoke checks, DNF installation and shell compilation separately.
It emits `live-result.json` even on a handled failure. Preserve this alongside
`serial.log`, `manifest.json`, `result.json` and text transcripts. Never archive
the per-VM private key, cloud-init seed or disk overlay.

## Reproducibility boundary and rollback

The base image URL/hash and virtual machine model (`virt-8.2`, `neoverse-n1`, TCG)
are pinned. Firmware hashes, seed hash and QEMU versions are recorded per prepare.
Retain the same QEMU/firmware packages to reproduce an environment. Firmware
binaries are not bundled or asserted interchangeable. Keys and instance IDs are
intentionally unique. RPM repositories, CI container tag and dependencies still
move; fully locked package snapshots and byte-identical output images are **not
implemented**. This is a repeatable development recipe, not a reproducible distro
release yet.

Stop QEMU before cleanup. Delete only the selected `build/qemu/<name>` directory
to roll back its writes. Keep the image cache for reuse or remove that ordinary
file separately. No disk/partition/bootloader rollback is required because no
physical storage is touched. Do not copy raw logs publicly without reviewing
potential host keys, environment details and network output.
