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
chroot . ash -c 'tazpkg get-install python clonezilla python-psutil perl-uri linux-nfsd nfs-utils locale-fr'
for file in {python-tftpy-0.8.0.tazpkg,fusioninventory-agent-2.4.2.tazpkg,perl-universal-require-0.18.tazpkg,perl-file-which-1.22.tazpkg,perl-treepp-0.43.tazpkg}; do
    curl -O https://agents.siveo.net/imaging/${file}
done
chroot . ash -c 'tazpkg install *.tazpkg'
chroot . ash -c 'adduser -D siveo'
chroot . ash -c 'echo -e "siveo\nsiveo" | passwd siveo'

rm -f ./*.tazpkg
rm -f ./etc/resolv.conf
rm -f ./var/cache/tazpkg/5.0/packages/*
umount ./proc

# Disable kernel low level messages in the console
sed -i 's/^#kernel\.printk.*/kernel.printk = 3 4 1 3/' etc/sysctl.conf

# Define services to be started automatically
sed -i '/^RUN_DAEMONS=/ s/"$/ nfsd dropbear"/' ./etc/rcS.conf

# Define pre-login message
sed -i 's/^MESSAGE=.*$/MESSAGE="Welcome to SIV3O Pulse diskless environment\nLog on with root/root or siveo/siveo"/' ./etc/rcS.conf
