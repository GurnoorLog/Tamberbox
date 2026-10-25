# Orange Pi 5 Ultra: bring-up checklist

**Absolute rule:** an image for Orange Pi 5 or 5 Plus is **not** an established working image for Orange Pi 5 Ultra. The exact board, boot layout, DTB, kernel modules, GPU and NPU dependencies must be checked. The board may have different peripherals even with the same SoC family.

## Verified external starting points
- Official Orange Pi 5 Ultra support/manual: https://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-5-Ultra.html
- Official Orange Pi 5 Ultra wiki: https://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_5_Ultra
- Armbian Orange Pi 5 Ultra board entry (community support): https://www.armbian.com/boards/orangepi5-ultra
- AlmaLinux aarch64 cloud reference: https://wiki.almalinux.org/cloud/Generic-cloud.html

## Golden-image evidence inventory (collect **read-only**)
On a **known-good** existing installation:

```bash
uname -a
cat /etc/os-release
cat /proc/device-tree/model 2>/dev/null || true
find /boot -maxdepth 3 -type f | sort | head -100
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL
lspci -nn 2>/dev/null || true
```

Capture boot source, exact board revision, kernel/module versions, `dmesg` extracts (redact secrets), boot arguments, DTB path, graphics DRM/KMS state and network chipset. **Do not capture passwords, tokens, MAC addresses or serial numbers in public logs.**

## Bring-up stages
- [ ] Identify boot media, U-Boot version/config, partitions and exact DTB on the known-good Ultra.
- [x] Build an AlmaLinux 10 aarch64 VM in QEMU using official checked cloud image; validate DNF and basic services.
- [ ] Choose test SD card. Make backup/recovery plan and confirm target device before any writing.
- [x] Produce isolated test image that combines vetted board-specific boot chain/kernel/modules with AlmaLinux rootfs.
- [ ] Serial console / HDMI verifies boot messages and login.
- [ ] `uname`, `/etc/os-release` and rootfs packages demonstrate the intended combination.
- [ ] Check wired/wireless network, HDMI, USB, NVMe and audio, logging successes and failures.
- [ ] Validate accelerated graphics separately (DRM, Mesa/Panfrost/Panthor/vendor stack as applicable).
- [ ] Validate NPU via a *real inference test* and compatible RKNN runtime if legally redistributable.
- [ ] Test clean shutdown/reboot, filesystem integrity and rollback.

## Explicit unknowns
The selected donor DTB/boot offsets and kernel bundle are inspected in [M2 boot-chain results](m2-boot-chain.md). Qt compilation/X11 runtime and offline image assembly are verified. Actual board boot, driver behavior, SDDM, accelerated graphics, NPU and power characteristics remain unverified.

## Safeguards
Never let exploratory agents flash the existing working drive. Use a disposable card and a physical recovery plan. No unattended `dd`, `flashcp`, `fdisk`, `parted`, `mkfs`, `u-boot-install`, `grub-install`, or raw eMMC/SPI write scripts in the default workflow. Any future flash helper must be interactive and opt-in.
