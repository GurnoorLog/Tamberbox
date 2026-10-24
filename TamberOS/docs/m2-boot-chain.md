# Exact-Ultra boot bundle and limitations

The selected donor is Armbian community `26.11.0-trunk.108`, Orange Pi **5 Ultra**,
Trixie minimal, vendor kernel **6.1.172**. Its release URL, size and SHA256 are in
`scripts/image/donor.lock.json`. The bytes were downloaded and matched the GitHub
release asset digest. That is HTTPS/API provenance, not independent signature
verification of the Armbian release. The donor is a community nightly, not a
vendor-certified release or a record of testing this user's board.

## Observed from the actual image

- GPT, one ext4 root partition, sectors **32768–4765695** (512-byte sectors).
- Boot firmware occupies the area before the 16 MiB root partition. Assembly
  preserves bytes from 32 KiB through that boundary. GPT identifiers/CRCs change
  independently; no guessed loader offsets are written.
- Actual binary strings identify **U-Boot/SPL 2017.09**, build
  `2017.09-S39cd-Pa589-H1795-V61a0-Bb936-R448a`, dated 2026-10-19.
  This supersedes the M1 moving/source-only U-Boot inference for this donor.
- `/etc/armbian-release` identifies `BOARD=orangepi5-ultra` and build commit
  `fac57a02f`, resolved to `fac57a02f1c6ff2221a3f3099a1094dcdf41be26`.
- Kernel and modules: **6.1.172-vendor-rk35xx**; DTB:
  `rockchip/rk3588-orangepi-5-ultra.dtb`. Kernel configuration enables 4 KiB ARM64
  pages, initramfs, devtmpfs, ext4, cgroups, seccomp and SELinux.
- Armbian boot.scr loads `Image`, `uInitrd` and the selected DTB, then uses `booti`.
  Root is selected by a new ext4 UUID, not a guessed `/dev/mmcblk0p1` name.
- A fresh AlmaLinux dracut initramfs replaces the Debian initramfs. Matching board
  kernel/DTBs/modules/firmware are copied together; stock AlmaLinux EFI boot and
  generic kernel are not transplanted onto the board.

The boot chain is RK3588 BootROM → SD loader/DDR initialization → SPL/trusted
firmware/U-Boot → U-Boot script → Linux/DTB/Alma initramfs → AlmaLinux root.
Exact loaded firmware revisions and boot precedence on the user's unit still
require the physical serial log. Preserving a donor region is not proof it will
be selected over pre-existing SPI firmware.

## Driver boundaries

The [pinned board definition](https://github.com/armbian/build/blob/fac57a02f1c6ff2221a3f3099a1094dcdf41be26/config/boards/orangepi5-ultra.csc)
selects the exact DTB, `spl-blobs`, GPT and SDIO bcmdhd. The
[bcmdhd extension](https://github.com/armbian/build/blob/fac57a02f1c6ff2221a3f3099a1094dcdf41be26/extensions/bcmdhd.sh)
builds an external DKMS module; the candidate preserves donor module bytes rather
than rebuilding against different headers. Check the extracted manifest for
actual presence; do not assume a requested DKMS build succeeded upstream.

Vendor Bluetooth requires the `SYN43711A0.hcd` firmware and a patchram service on
UART7 (`ttyS7`). The Debian patchram executable/service is not copied blindly into
AlmaLinux, so Bluetooth initialization remains an explicit integration gap.
HDMI/ES8388 audio aliases, GPU user-space ABI, compositor, Wi-Fi power management,
thermals and NPU runtime require device testing. Do not assume upstream Panthor
Mesa works with this vendor Mali kernel.

## Reproducibility and redistribution

The donor checksum pins its whole boot/kernel/module/firmware combination. Each
extracted regular file gets a SHA256 manifest. The image manifest records the
result, and CI records the AlmaLinux container digest and installed RPM NEVRAs.
The container digest and 178 exact rootfs package NEVRAs (plus the expected signing-key database entry) are pinned in
`rootfs.lock.json`; package availability failures stop the build. Downloaded RPM
checksums are recorded. Build-tool versions, filesystem timestamps and a permanent
RPM mirror are not frozen, so byte-identical output is not claimed.

U-Boot's included GPL notice and donor provenance are retained in the image;
firmware notices remain in `/usr/lib/firmware/LICENSES`. Those notices do not
constitute a complete per-blob redistribution clearance. No board binaries are
committed to Git or included in the source archive. The build downloads the donor
from upstream; public redistribution of a final OS release needs a complete
license/source-offer review. The official Tamber boot artwork is preserved in
`references/final-concept`; no generic graphical boot theme replaces it. This
headless candidate deliberately uses diagnostic boot output.

## Resolved loader provenance

The donor metadata resolves Radxa U-Boot to commit
`39cd993e5d6296635438e84f4576b3a9bf76f86e`, source branch
`next-dev-v2024.10`, with Armbian patch directories recorded in the evidence.
The branch name differs from the binary's 2017.09 version string.
The target build declares `rk3588_bl31_v1.48.elf`. DDR initialization is contained
in the pinned loader; its independent component version is not claimed.
`idbloader.img` is 321,536 bytes at offset 32,768; `u-boot.itb` is 1,457,152
bytes at offset 8,388,608. Both exactly match the raw donor. See
`evidence/m2/boot-components.json` for hashes. SPI loader files are never used.

The extracted DTB identifies `RK3588 OPi 5 Ultra`, compatible
`rockchip,rk3588-orangepi-5-ultra`. Both vendor `bcmdhd.ko` and DKMS
`bcmdhd_sdio.ko` exist; driver selection/conflicts remain a Wi-Fi hardware test.
Kernel updates are outside AlmaLinux RPM management in this experiment; this
is not a supported production update path.
