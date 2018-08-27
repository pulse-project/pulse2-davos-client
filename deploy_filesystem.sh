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
mount devpts /dev/pts -t devpts
cp /etc/resolv.conf ./etc/resolv.conf
chroot . bash -c 'mkdir /boot'
chroot . bash -c 'apt-get update && apt-get -y install apt-utils python-minimal libpython-stdlib fusioninventory-agent dos2unix linux-firmware python-tftpy python-psutil efivar ash && exit'
cp /root/partclone_0.2.89-4_amd64.deb /root/clonezilla_3.21.13-1_all.deb /root/drbl_2.20.11-1_all.deb .
chroot . bash -c 'dpkg -i partclone_0.2.89-4_amd64.deb clonezilla_3.21.13-1_all.deb drbl_2.20.11-1_all.deb'
chroot . bash -c 'ln -s /usr/lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service'
chroot . bash -c 'rm -frv /opt/*'
chroot . bash -c 'echo efivars >> /etc/modules'
chroot . bash -c 'apt-get autoclean -y '
chroot . bash -c 'apt-get clean -y '
chroot . bash -c 'apt-get autoremove -y '
chroot . bash -c 'find /var/lib/apt/lists/ -maxdepth 1 -type f -exec rm -v {} \;'

rm -f ./etc/resolv.conf
umount ./proc

# Removing APT cache
rm -rf var/cache/apt

# Skip keymap selection (in deploy mode)
[ -z $DEBUG ] && cat /dev/null > etc/ocs/ocs-live.d/S05-lang-kbd-conf

# Disable kernel low level messages in the console
sed -i 's/^#kernel\.printk.*/kernel.printk = 3 4 1 3/' etc/sysctl.conf
