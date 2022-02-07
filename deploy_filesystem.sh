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
#chroot . bash -c 'apt remove nic-firmware -y'
for i in python-funcsigs_1.0.2-4build1_all.deb python-ipaddress_1.0.17-1build1_all.deb python-tftpy_0.6.0-1_all.deb  python-mock_3.0.5-1build1_all.deb python-psutil_5.5.1-1ubuntu4_amd64.deb python-pbr_5.5.1-0ubuntu1_all.deb python-six_1.16.0-3_all.deb python-pkg-resources_44.1.1-1.2_all.deb python-setuptools_44.1.1-1.2_all.deb; do cp DEBS/$i . ; done
chroot . bash -c 'dpkg -i python-funcsigs_1.0.2-4build1_all.deb python-ipaddress_1.0.17-1build1_all.deb python-tftpy_0.6.0-1_all.deb  python-mock_3.0.5-1build1_all.deb python-psutil_5.5.1-1ubuntu4_amd64.deb python-pbr_5.5.1-0ubuntu1_all.deb python-six_1.16.0-3_all.deb python-pkg-resources_44.1.1-1.2_all.deb python-setuptools_44.1.1-1.2_all.deb'
chroot . bash -c 'apt update && apt -y install apt-utils python2-minimal libpython2-stdlib fusioninventory-agent dos2unix linux-firmware efivar ash python-six && exit'
chroot . bash -c 'dpkg -l |grep six'
#cp /root/partclone_0.2.89-4_amd64.deb /root/clonezilla_3.21.13-1_all.deb /root/drbl_2.20.11-1_all.deb .

#chroot . bash -c 'dpkg -i partclone_0.2.89-4_amd64.deb clonezilla_3.21.13-1_all.deb drbl_2.20.11-1_all.deb'
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
