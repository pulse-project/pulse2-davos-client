#!/bin/bash
#set -e

# =====================================================
# NOTE :
#  This script will be run in a temporary squashfs dir
#  $1 is the original dir on the caller script (build.sh)
# =====================================================

# Copy all fs files to squashfs root
cp -rvf $1/squashfs_override/* ./

# vim instead of vim.tiny
# Very useful for debug
cp usr/bin/vim.tiny usr/bin/vim

# Installing additional packages
mount -t proc none ./proc
cp /etc/resolv.conf ./etc/resolv.conf
chroot . bash -c 'apt-get update && apt-get -y install python-minimal libpython-stdlib fusioninventory-agent dos2unix && exit'

rm -f ./etc/resolv.conf
umount ./proc

# Removing APT cache
rm -rf var/cache/apt

# Skip keymap selection (in deploy mode)
[ -z $DEBUG ] && cat /dev/null > etc/ocs/ocs-live.d/S05-lang-kbd-conf

# Disable kernel low level messages in the console
sed -i 's/^#kernel\.printk.*/kernel.printk = 3 4 1 3/' etc/sysctl.conf
