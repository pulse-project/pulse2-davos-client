#!/bin/bash
#set -e

# =====================================================
# NOTE :
#  This script will be run in a temporary build dir
#  $1 is the original dir on the caller script (build.sh)
# =====================================================

# Copy all fs files to squashfs root
cp -rvf $1/squashfs_override/* ./

# Installing additional packages
mount -t proc none ./proc
mount devpts /dev/pts -t devpts
cp /etc/resolv.conf ./etc/resolv.conf
chroot . bash -c 'apt install clonezilla drbl partclone -y'
chroot . bash -c 'adduser -D pulse'
chroot . bash -c 'echo -e "pulse\npulse" | passwd pulse'

# Fix clonezilla language Setup
chroot . ash -c 'cd /usr/share/drbl/lang/bash/ && ln -s en_US en_US.UTF-8'

# Save packages for future use
mkdir -p /tmp/downloads/
cp ./*.tazpkg /tmp/downloads/
cp ./var/cache/tazpkg/5.0/packages/*.tazpkg /tmp/downloads/

# Clean the FS before building the rootfs
rm -f ./*.tazpkg
rm -f ./etc/resolv.conf
rm -f ./var/cache/tazpkg/5.0/packages/*
umount ./proc

# Disable kernel low level messages in the console
sed -i 's/^#kernel\.printk.*/kernel.printk = 3 4 1 3/' ./etc/sysctl.conf

# Define services to be started automatically
sed -i '/^RUN_DAEMONS=/ s/"$/ dropbear"/' ./etc/rcS.conf

# Configure dropbear
sed -i '/^DROPBEAR_OPTIONS=/ s/-w //' ./etc/daemons.conf

# Define pre-login message
sed -i 's/^MESSAGE=.*$/MESSAGE="Welcome to SIV3O Pulse diskless environment"/' ./etc/rcS.conf

# Run davos at startup
sed -i 's#^tty1:.*$#tty1::wait:/usr/sbin/davos#' ./etc/inittab
