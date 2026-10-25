# TamberOS status · 2026-10-25

**M1 complete. M2 in progress; physical boot acceptance NOT met.** No physical
storage, existing Armbian installation or TamberBox firmware was modified.
M1 evidence is retained in [status-m1.md](status-m1.md); it was not rerun.

## Verified M2 results

- Native ARM64 image build [40120580544](https://github.com/GurnoorLog/Tamberbox/actions/runs/40120580544)
  passed at commit `cfb3f42edb01482bd0bc27defc8605fef33dd49d`.
  It produced a 2,441,084,928-byte ordinary image file with AlmaLinux 10.2 userspace,
  board-specific `6.1.172-vendor-rk35xx` kernel and matching DTBs/modules/firmware.
- GPT CRCs, ARM64 kernel magic, exact vendor Ultra DTB, 3,278 matching donor assets,
  root UUID consistency and ext4 check passed. Alma dracut generated the initramfs;
  its listing includes systemd. See [image evidence](evidence/m2/image-success/).
- Downloaded candidate SHA256 independently recomputed locally:
  `a34411e36ae11c463f546c06ee64c5d5785e69a9ab7bf7446f344bbaf1dbe988`.
- Real image personalization with a disposable Ed25519 public key passed key
  readback and e2fsck. Only a new image file was written. See
  [personalization log](evidence/m2/personalization.txt). This is not an SSH login test.
- 32 Python unit tests, project structure, original asset preservation, shell-script
  syntax and prototype JavaScript syntax checks pass locally. Synthetic unit
  fixtures test guard behavior; they are not hardware evidence.
- Native ARM64 Qt/QML compilation and **2/2 CTest cases passed on X11/Xvfb** in
  [run 40120168700](https://github.com/GurnoorLog/Tamberbox/actions/runs/40120168700).
  Tests launch a real process from a desktop entry and use keyboard navigation
  to launch a separate Qt graphical window. [Build/test log](evidence/m2/shell-arm64-x11-ci.txt)
  and [screenshots](evidence/m2/x11/) are retained. Rendering used software, not GPU.

## Candidate and reproducibility

[Download the unpersonalized image artifact](https://github.com/GurnoorLog/Tamberbox/actions/runs/40120580544/artifacts/12570892541).
GitHub login may be required; CI artifacts expire. Rebuild from the pinned source
using [the hardware testing guide](m2-hardware-testing.md). The image has no shared
password or usable public key until personalized. It is a headless candidate;
the shell is tested separately inside a Linux graphical session.

The container digest, donor SHA256 and 178 RPM NEVRAs plus signing-key inventory
are pinned. RPM checksums and installed inventory are recorded. Build tools,
timestamps and permanent package hosting are not frozen: bit-identical builds
and indefinite upstream package availability are not claimed. Armbian provenance
is a release API digest, not an independently authenticated release signature.
M1's independently authenticated AlmaLinux image signature remains separate evidence.

## Remaining limitations and acceptance gates

No Orange Pi boot, serial login, HDMI, Ethernet, Wi-Fi, Bluetooth, USB, NVMe, audio,
GPU or thermal result is claimed. Bluetooth patchram/UART7 service integration is
missing; vendor GPU ABI compatibility is unverified. NPU, SDDM, compositor,
production RPM/update management and boot artwork implementation remain future work.
The original nine concepts and sunglasses-llama boot reference are preserved.

The shell has real app discovery/launching, search, keyboard access and persistent
appearance settings. Its dock indicators mean launch accepted, not running-window
tracking. External window management, blur, icons/reordering and system controls
are not implemented. It has not run on the Orange Pi.

CI emitted warnings from rootless donor ownership extraction, missing initramfs
syslog logging, a user skeleton copy and unmounted /proc in offline systemctl.
Imported ownership is normalized; subsequent image checks and account/key tests
pass. These warnings are retained in the build log and are not evidence of runtime
service correctness. The log omits repetitive debugfs ownership warnings only.

M2 completion requires real serial/HDMI boot, correct identity, basic I/O/network,
clean shutdown/reboot and recovery using a separate microSD. Follow the explicit
exact-device approval stop gate before any physical write. Keep the original
Armbian card disconnected. No flash command is included.

## Rollback

Discard only disposable build files or revert the feature-branch commits.
No host boot or physical storage changes need reversal. For future hardware tests,
power off and restore the untouched original card; never compensate by writing SPI.
