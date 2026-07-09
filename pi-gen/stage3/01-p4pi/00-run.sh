#!/bin/bash -e

# Display logo on TTY login
install -m 644 files/motd "${ROOTFS_DIR}/etc/"

on_chroot << EOF
echo 'deb http://download.opensuse.org/repositories/home:/p4lang/Raspbian_11/ /' | tee /etc/apt/sources.list.d/p4pi-kernel.list
curl -fsSL https://download.opensuse.org/repositories/home:p4lang/Raspbian_11/Release.key | gpg --dearmor > /etc/apt/trusted.gpg.d/home_p4lang.gpg

echo 'deb http://download.opensuse.org/repositories/home:/p4lang/Debian_11/ /' | tee /etc/apt/sources.list.d/home:p4lang.list
curl -fsSL https://download.opensuse.org/repositories/home:p4lang/Debian_11/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_p4lang.gpg > /dev/null

apt-get -y update

# TEMP DIAGNOSTIC: enumerate what the home:p4lang repos actually publish, so we
# can see why p4lang-pi/p4lang-p4c/p4lang-bmv2 are "Unable to locate". Remove
# once the correct package source is confirmed.
echo "===== DIAG: home:p4lang Packages indices ====="
for f in /var/lib/apt/lists/*p4lang*Packages*; do
  echo "--- \$f ---"
  grep -E '^(Package|Architecture|Version):' "\$f" || true
done
echo "===== DIAG: apt-cache search for p4-related packages ====="
apt-cache search . | grep -iE 'p4lang|bmv2|p4c|t4p4s|\bpi\b' || true
echo "===== DIAG: apt-cache policy for the missing packages ====="
apt-cache policy p4lang-pi p4lang-p4c p4lang-bmv2 || true
echo "===== DIAG: end ====="

wget https://raw.githubusercontent.com/p4lang/behavioral-model/main/tools/p4dbg.py
mv p4dbg.py /usr/lib/python3/dist-packages/
EOF
