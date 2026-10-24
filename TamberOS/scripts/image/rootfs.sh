#!/bin/bash
# Run only in the disposable AlmaLinux ARM64 build container with /work mounted.
set -euo pipefail
[[ $(uname -m) == aarch64 && -f /run/.containerenv || $(uname -m) == aarch64 && -f /.dockerenv ]] || { echo 'Requires isolated ARM64 container'; exit 2; }
cd /work
root=/work/build/m2/alma-root
[[ ! -e "$root" ]] || { echo 'Fresh rootfs required'; exit 2; }
mkdir -p "$root"
dnf --releasever=10.2 -y --setopt=install_weak_deps=False install python3 dracut kmod tar xz e2fsprogs shadow-utils
packages=(almalinux-release bash coreutils systemd systemd-udev NetworkManager openssh-server sudo util-linux e2fsprogs dracut kmod shadow-utils selinux-policy-targeted policycoreutils iproute iputils ethtool pciutils usbutils)
dnf --installroot="$root" --releasever=10.2 -y --setopt=install_weak_deps=False install "${packages[@]}"
cp -a build/m2/donor-assets/boot "$root/"
cp -a build/m2/donor-assets/usr/lib/modules "$root/usr/lib/"
cp -a build/m2/donor-assets/usr/lib/firmware "$root/usr/lib/"
mkdir -p "$root/usr/share/tamberos/donor-licenses"
cp -a build/m2/donor-assets/licenses/. "$root/usr/share/tamberos/donor-licenses/"
# The Debian initramfs is not reused with an AlmaLinux userspace.
rm -f "$root"/boot/initrd.img-* "$root"/boot/uInitrd*
kver=6.1.172-vendor-rk35xx
depmod -b "$root" "$kver"
dracut --sysroot "$root" --force --no-hostonly --no-hostonly-cmdline --kver "$kver" --add 'rootfs-block kernel-modules' "$root/boot/initramfs-$kver.img"
chroot "$root" useradd --create-home --shell /bin/bash --groups wheel tamber
printf 'tamber ALL=(ALL) NOPASSWD: ALL\n' > "$root/etc/sudoers.d/tamber-development"
chmod 440 "$root/etc/sudoers.d/tamber-development"
mkdir -p "$root/home/tamber/.ssh"
chmod 700 "$root/home/tamber/.ssh"
# A supplied public key is optional for CI; unpersonalized builds have no usable login.
if [[ -f /work/build/m2/authorized_key.pub ]]; then
 cp /work/build/m2/authorized_key.pub "$root/home/tamber/.ssh/authorized_keys"
 chmod 600 "$root/home/tamber/.ssh/authorized_keys"
fi
chroot "$root" chown -R tamber:tamber /home/tamber/.ssh
printf 'PasswordAuthentication no\nPermitRootLogin no\n' > "$root/etc/ssh/sshd_config.d/10-tamber.conf"
printf 'tamberos-ultra\n' > "$root/etc/hostname"
printf 'UUID=6b824c82-df58-5da7-922c-764d173a5bca / ext4 defaults,noatime 0 1\n' > "$root/etc/fstab"
printf 'SELINUX=permissive\nSELINUXTYPE=targeted\n' > "$root/etc/selinux/config"
touch "$root/.autorelabel"
: > "$root/etc/machine-id"
rm -f "$root/etc/ssh/ssh_host_"*
chroot "$root" systemctl enable NetworkManager sshd serial-getty@ttyS2.service
chroot "$root" systemctl set-default multi-user.target
chroot "$root" rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort > build/m2/rpm-inventory.txt
chroot "$root" dnf clean all
