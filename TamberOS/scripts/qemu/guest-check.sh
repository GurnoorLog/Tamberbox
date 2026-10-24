#!/bin/bash
# Runs only inside the disposable guest. No installation or upgrades.
set -u
if [ ! -f /etc/tamber-dev-vm ] || [ "$(uname -m)" != aarch64 ] || [ "$(systemd-detect-virt 2>/dev/null)" != qemu ]; then
    echo 'Refusing to run outside the disposable Tamber ARM64 QEMU guest' >&2
    exit 2
fi
proxy_args=()
if [ -f /etc/tamber-dev-proxy ]; then
    proxy=$(cat /etc/tamber-dev-proxy)
    export http_proxy="$proxy" https_proxy="$proxy"
    proxy_args=("--setopt=proxy=$proxy")
    echo 'TAMBER_NETWORK_TRANSPORT host-proxy (guest DNS not tested)'
else
    echo 'TAMBER_NETWORK_TRANSPORT direct'
fi
printf '\nTAMBER_M1_BEGIN\n'
uname -r
cat /etc/os-release
if [ "$(uname -m)" = aarch64 ] && grep -qx 'ID="almalinux"' /etc/os-release && grep -qx 'VERSION_ID="10.2"' /etc/os-release; then
    echo 'TAMBER_CHECK identity PASS'
else
    echo 'TAMBER_CHECK identity FAIL'
fi
if curl --fail --max-time 30 --silent --output /dev/null https://repo.almalinux.org/; then
    echo 'TAMBER_CHECK network PASS'
else
    echo 'TAMBER_CHECK network FAIL'
fi
if timeout 240 dnf "${proxy_args[@]}" --releasever=10.2 --setopt=timeout=20 --setopt=retries=1 makecache --refresh; then
    echo 'TAMBER_CHECK dnf PASS'
else
    echo 'TAMBER_CHECK dnf FAIL'
fi
missing=0
for package in gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel rpm-build; do
    result=$(timeout 60 dnf "${proxy_args[@]}" --releasever=10.2 --enablerepo=crb --setopt=timeout=20 --setopt=retries=1 repoquery --available --qf '%{name}-%{evr}.%{arch}' "$package")
    rc=$?
    printf '%s\n' "$result"
    if [ "$rc" -ne 0 ] || ! printf '%s\n' "$result" | grep -q "^${package}-"; then missing=1; fi
done
if [ "$missing" -eq 0 ]; then echo 'TAMBER_CHECK packages PASS'; else echo 'TAMBER_CHECK packages FAIL'; fi
rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort
printf 'TAMBER_M1_END\n'
