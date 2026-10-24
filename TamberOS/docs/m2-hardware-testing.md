# M2: separate-microSD testing procedure

M2 is **not complete**. An offline-validated candidate is not a board boot test.
The existing Armbian microSD is the recovery system and must remain untouched.
The candidate is headless AlmaLinux; the session shell is a separate development
application and does not establish a working Ultra graphics stack.

## Before any physical write — STOP gate

1. Shut down TamberBox normally. Remove and label the existing Armbian microSD.
   Keep it disconnected throughout candidate writing and initial testing. Disconnect
   optional NVMe/USB storage for the first boot when practical; do not modify SPI.
2. Use a separate microSD of at least 8 GB. Back up anything on that separate card.
3. On the development computer, identify the newly inserted card with
   `lsblk -o NAME,PATH,SIZE,MODEL,TRAN,MOUNTPOINTS`. Compare before/after insertion.
4. Provide the exact destination path, capacity, model, current mounts and explicit
   permission to erase **that separate card**. Obtain approval before writing.
   This package deliberately contains no flash helper or physical write command.
5. Verify the image SHA256 against its generated manifest. Personalize the image
   with your own public SSH key as described below. Never publish the private key.

Nothing in the build or personalization workflow writes physical storage. Any
future writing step requires a separate exact-device check and explicit approval.

## Build and personalize on an isolated development computer

Requirements: native ARM64 Linux, Docker, Python 3.11+, debugfs/e2fsprogs, xz,
U-Boot `mkimage`, and `fdtget` from device-tree-compiler. Run in the TamberOS source
root, not on the existing Armbian installation. The container writes only the
mounted source workspace. There are no loop mounts, host partitioning commands,
privileged containers, or device passthrough.

```sh
python3 scripts/image/donor.py
docker pull almalinux@sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b
docker run --rm -v "$PWD:/work" almalinux@sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b bash /work/scripts/image/rootfs.sh
sudo python3 scripts/image/assemble.py
sudo python3 scripts/image/validate.py
```

`sudo` here is needed to preserve rootfs ownership in an isolated development
workspace; the scripts accept no physical output target. All output goes under
`build/m2`. Existing outputs are refused. To repeat, use a separate clean source
checkout, retaining downloaded artifacts by their checked hashes if desired.

The CI candidate deliberately has no shared password or usable login key. To use
it, place the decompressed candidate at `build/m2/TamberOS-M2-ultra.img`, then:

```sh
python3 scripts/image/personalize.py --public-key /absolute/path/to/your_key.pub
```

This accepts only an Ed25519 public key and creates a **new** file named
`TamberOS-M2-ultra-personalized.img`, verifies key readback and filesystem
consistency, and writes `personalized-manifest.json`. Login is `tamber`, with
passwordless sudo in this development image. Root/password SSH login is disabled.
This is a trusted-lab development policy, not a production security configuration.

Alternatively copy a public key to `build/m2/authorized_key.pub` before rootfs
creation. Preserve the resulting personalized image and SHA256 privately.

## First boot after the separate writing approval

Use stable power, Ethernet and HDMI. Connect a known-good 3.3 V UART adapter only
according to the **exact Ultra** manual/pinout; do not connect adapter VCC or use
5 V signalling. The selected boot script uses UART2/ttyS2 at **1500000 baud, 8N1**.
Capture the complete serial log from power-on. Actual boot-source precedence may
depend on existing SPI/eMMC firmware; this package does not alter it.

Expect board firmware → U-Boot → boot.scr → Image + uInitrd + Ultra DTB → AlmaLinux
systemd. Wait for first-boot SELinux relabeling, if required. SELinux is permissive
for bring-up and must be reviewed before production. Discover the test IP through
your router, then `ssh -i /path/to/private_key tamber@TEST_IP`.

Record `uname -r`, `/etc/os-release`, `/proc/device-tree/model`, and
`/proc/cmdline`. Acceptance requires the exact Ultra model, AlmaLinux 10.2,
`6.1.172-vendor-rk35xx`, the expected root UUID, and a root filesystem on the test
microSD. If any differ, stop; do not compensate by writing SPI or another disk.

## Peripheral acceptance matrix

| Area | Test on the candidate | Pass evidence / limits |
|---|---|---|
| Boot/storage | Serial power-on through login; `findmnt /`; `lsblk -f` | Correct test-card root, no fallback into existing Armbian; no MMC errors |
| HDMI | Console at intended resolution; hotplug once | Stable output and recovery; desktop/GPU acceleration is a separate test |
| Ethernet | `ip -brief address`; `nmcli device`; ping router; HTTPS/DNF metadata refresh | DHCP, DNS, verified TLS; successful real DNF transaction |
| Wi-Fi | `nmcli device`; list APs; connect using local interactive secret entry | Association, DHCP and traffic; record module/firmware, redact SSID/MAC |
| Bluetooth | Inspect `bluetoothctl list`, then pair a test device if available | Vendor UART7 patchram loader is **not integrated**; currently expected blocked |
| USB 2/3 | Known keyboard/mouse, `lsusb -t`; read a sacrificial USB test file | Both port classes, no disconnects; never write existing disks |
| NVMe | `lspci -nn`, device enumeration and read-only inspection | Enumerates without PCIe errors; no formatting or write benchmark |
| Audio | Enumerate ALSA devices; play a local test signal at low volume | HDMI/ES8388 routing checked separately; user-space audio tools may need installation |
| GPU | Inspect DRM nodes and kernel log, then renderer identity in a configured graphics session | Hardware renderer, not llvmpipe; vendor Mali kernel is not assumed Mesa/Panthor compatible |
| Thermals | Read thermal zones at idle and under a bounded 60-second CPU workload | Values plausible, cooling responds, no reset; no invented safe maximum |
| Recovery | Clean shutdown/reboot twice, then power off and restore original card | Original Armbian boots unchanged; no SPI/eMMC/NVMe writes |

Use `python3 scripts/board_inventory.py` for bounded read-only inventory. Keep
raw logs private until MACs, serials, IPs, usernames and secrets are reviewed.
For each row record PASS, FAIL or NOT TESTED, command, timestamp, hardware setup
and evidence filename. Missing drivers/services are failures or limitations, not
zero readings. NPU inference is outside this candidate and remains unverified.

M2 acceptance needs real serial and HDMI boot, correct identity, basic I/O and
network operation, clean shutdown/reboot, and demonstrated recovery. Offline
checks cannot satisfy those hardware gates.
