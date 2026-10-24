# M1 feasibility — 2026-10-23

Evidence levels: **observed** means retrieved primary source or package listing;
**tested** means executed here. Neither implies Orange Pi compatibility.
Machine-readable URLs, response hashes and selected RPM names are recorded in
[evidence/source-observations.json](evidence/source-observations.json).

| Component | SOURCE / observed version | TESTED here | UNKNOWN / next test |
|---|---|---|---|
| AlmaLinux userspace | [Official cloud repository](https://repo.almalinux.org/almalinux/10/cloud/aarch64/images/), GenericCloud 10.2 build 20261012.0 aarch64 | Downloaded 478,937,088 bytes; SHA256 matches the lock and upstream CHECKSUM | Signature authentication, UEFI boot, login, DNF execution |
| Qt Quick/QML | [10.2 AppStream aarch64 listing](https://repo.almalinux.org/almalinux/10.2/AppStream/aarch64/os/Packages/): qt6-qtbase-devel 6.10.1-1.el10.alma.1; qt6-qtdeclarative-devel 6.10.1-1.el10_2.1 | Listing retrieved, not installed | Dependency resolution, C++/QML compilation and graphical runtime |
| Build/RPM tools | Same AppStream: cmake 3.31.8-1.el10; rpm-build 4.19.1.1-23.el10.alma.1 | Listing retrieved | Actual build, complete package lock and RPM specification (M5) |
| Plymouth | Same AppStream: 24.004.60-17.el10.alma.2 and script plugin | Listing retrieved | Theme and usable KMS display; do not edit initramfs now |
| SDDM | No SDDM filename found in retrieved BaseOS/AppStream/CRB listings | Search of those listings only | EPEL source/dependencies and runtime; no global absence claim |
| Ultra board configuration | [Armbian pinned board file](https://github.com/armbian/build/blob/fac57a02f1c6ff2221a3f3099a1094dcdf41be26/config/boards/orangepi5-ultra.csc) | Source retrieval | Actual board revision, boot medium and serial evidence |
| U-Boot | Board config selects `orangepi-5-ultra-rk3588_defconfig`; [family source](https://github.com/armbian/build/blob/fac57a02f1c6ff2221a3f3099a1094dcdf41be26/config/sources/families/rockchip-rk3588.conf) selects Radxa `next-dev-v2024.10` | Source retrieval only | Transitive source commits, patch set, DDR/BL31 hashes/licenses and exact media layout |
| Kernel/DTB | Board file selects `rockchip/rk3588-orangepi-5-ultra.dtb`, vendor/current/edge targets, `spl-blobs`, GPT | Source retrieval | Matching kernel config/modules/DTB/initramfs; stock Alma kernel on Ultra is not established |
| Wi-Fi / Bluetooth | Board source enables SDIO bcmdhd; vendor Bluetooth loads SYN43711A0 on ttyS7; non-vendor path uses hci_bcm firmware naming | Source retrieval | Firmware licensing, actual board devices, radio operation under AlmaLinux |
| Audio | Board source names HDMI1, HDMI input and ES8388 paths | Source retrieval | Routing, codec drivers and capture/playback |
| GPU/display | [Mesa Panfrost docs](https://docs.mesa3d.org/drivers/panfrost.html) list Mali G610; GPU rendering and display-controller support are distinct | Documentation only | Compatible kernel Panthor/firmware/Mesa/KMS combination and real accelerated rendering |
| NPU | [Rockchip RKNN upstream](https://github.com/airockchip/rknn-toolkit2) | No runtime or binaries installed | Driver/runtime ABI, redistributable licenses, real model output and latency |
| Ethernet/USB/NVMe/HDMI | [Exact Ultra vendor page](https://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-Ultra.html) | Hardware specification only | All actual functionality with the selected kernel/userspace |

## Engineering decision

Keep AlmaLinux 10.2 aarch64, Qt 6 Quick and the existing application architecture.
Use a headless QEMU virtual ARM machine first. Select the AppStream Qt development
packages based on observed availability, with DNF confirmation before builds.
Do not add EPEL or pick SDDM/compositor based on assumptions. Current CI requests
an ARM64 AlmaLinux 10.2 container compile; it has not been run remotely.

For M2, evaluate one coherent exact-Ultra Armbian boot/kernel/DTB/modules bundle,
not independently mixed versions. The pinned framework commit is a research
anchor, not a fully pinned board build: referenced branches and blobs still need
resolution. No board binaries are imported. Board boot offsets are deliberately
not guessed from another Orange Pi model. The poster is visual direction, not
hardware evidence.

## Source drift

The web index and raw repository fetch showed different revisions of the moving
Armbian main branch. All source findings above use the exact commit linked here;
do not combine values from cached search results with this commit. Consult the
stored source-response hashes when rechecking. The Armbian download page is a
candidate-image catalog, not proof that any listed image was downloaded or tested.

## Next hardware evidence

`scripts/board_inventory.py` reads a small allowlist and writes JSON to stdout.
It does not connect to TamberBox. On a separately authorized known-good board,
run it without sudo and privately review the report. It intentionally cannot
prove boot medium or U-Boot version: record those later from the serial boot log
and a carefully reviewed read-only inventory. No flashing belongs in M1.

## Kernel/firmware source trace (not a build manifest)

At the same pinned framework commit, [rockchip_vendor_common.inc](https://github.com/armbian/build/blob/fac57a02f1c6ff2221a3f3099a1094dcdf41be26/config/sources/families/include/rockchip_vendor_common.inc)
selects `armbian/linux-rockchip`, branch `rk-6.1-rkr7.2` for `vendor` (6.1).
Its vendor-next 6.12 branch is not selected as the initial target here.
[rockchip64_common.inc](https://github.com/armbian/build/blob/fac57a02f1c6ff2221a3f3099a1094dcdf41be26/config/sources/families/include/rockchip64_common.inc)
contains RK3588 defaults for DDR blob
`rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.20_20250926.bin` and
`rk3588_bl31_v1.48.elf`. These names are source observations, not approved assets.
Their bytes, licenses, resolved source revisions and exact-board boot behavior
remain unverified. No RKUSB loader or firmware was downloaded or executed.
