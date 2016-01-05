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

# Additionnal packages installation
# Copying additional debs to /root
mkdir root/packages
cp -r $1/packages root/

# Installing additional packages
chroot . bash -c 'dpkg -i /root/packages/*.deb'

if [ -n $DEBUG ]; then
    # Chroot bash for debug mode
    chroot . bash
    # Installing debug packages
    chroot . bash -c 'dpkg -i /root/packages/debug/*.deb'

    # Copying a vim conf
    cp -r /root/.vim_runtime root/
    chroot . sh /root/.vim_runtime/install_awesome_vimrc.sh
fi

# Removing debs and APT cache
rm -rf root/packages
rm -rf var/cache/apt

# Skip keymap selection (in deploy mode)
[ -z $DEBUG ] && cat /dev/null > etc/ocs/ocs-live.d/S05-lang-kbd-conf

# Disable kernel low level messages in the console
sed -i 's/^#kernel\.printk.*/kernel.printk = 3 4 1 3/' etc/sysctl.conf
