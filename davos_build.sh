#!/bin/bash
set -e

# Edit these line to update slitaz version
version="rolling"
flavor="core64"
base_url="http://mirror.slitaz.org/iso/"

# =============================================================
# Don't edit anything below these lines
# =============================================================

file_name=slitaz-${version}-${flavor}.iso
full_url=${base_url}/${version}/${file_name}
old_pwd=$(pwd)
tempdir=$(mktemp -d)

echo "Downloading Slitaz ..."
[ ! -f $file_name ] && echo "Downloading Slitaz" && curl -O $full_url

# Sometimes we get html instead of real file
if [[ ! -f "$file_name" ||  $(stat -c%s "$file_name") -lt 1048576 ]]; then
  echo "Failed to download the right file, check URLs"
  exit 1
fi

# Entering temp directory
mv $file_name $tempdir
cd $tempdir

mkdir slitaz build target

# Mount slitaz iso
mount -o loop $file_name slitaz

# Move needed files to build dir and target dir
cp slitaz/boot/bzImage64 target/
cp slitaz/boot/rootfs.gz build/

# Unmount iso
umount slitaz

cd build

# Decompressing the rootfs
lzcat rootfs.gz | cpio -id
rm rootfs.gz
#sed 's/MULTICAST_ALL_ADDR="224.0.0.1"/MULTICAST_ALL_ADDR="239.254.1.255"/' -i etc/drbl/drbl-ocs.conf

# Run deploy script to patch the filesystem
$old_pwd/deploy_filesystem.sh $old_pwd/

# Recompress the new rootfs
find . -print | cpio -o -H newc | gzip -9 > ../target/rootfs.gz
cd ..

# Move built files to their final dir
mv -f target/* $old_pwd/var/lib/pulse2/imaging/davos/

# Remove temp dir
rm -r $tempdir


echo "Davos diskless environment built successfuly"
