#!/bin/bash
set -e

# Edit these line to update clonezilla version
version="20160210-wily"
arch="i386"
base_url="http://heanet.dl.sourceforge.net/project/clonezilla/clonezilla_live_alternative"

# =============================================================
# Don't edit anything below these lines 
# =============================================================

file_name=clonezilla-live-$version-$arch.zip
full_url=$base_url/$version/$file_name
old_pwd=$(pwd)
tempdir=$(mktemp -d)

echo "Downloading Clonezilla ..."
[ ! -f $file_name ] && echo "Downloading Clonezilla" && wget $full_url

# Sometimes we get html instead of real file
if [[ ! -f "$file_name" ||  $(stat -c%s "$file_name") -lt 1048576 ]]; then
  echo "Failed to download the right file, check URLs"
  exit 1
fi

# Entering temp directory
cp $file_name $tempdir
cd $tempdir

mkdir clonezilla build

# Unzip clonezilla zipfile
unzip "$file_name" -d clonezilla/

# Move needed files to build dir
for file in {filesystem.squashfs,initrd.img,vmlinuz}; do
  mv clonezilla/live/$file build/
done

cd build

# Decompressing the squashfs
unsquashfs filesystem.squashfs && rm filesystem.squashfs
cd squashfs-root

# Run deploy script to patch the filesystem
$old_pwd/deploy_filesystem.sh $old_pwd/
cd ..

# Recompress the new squashfs
mksquashfs squashfs-root/ fs.squashfs -noappend -always-use-fragments
rm -r squashfs-root/

cd ..

# Move builded files to their final dir
mv -f build/* $old_pwd/var/lib/pulse2/imaging/davos/

# Remove temp dir
rm -r $tempdir


echo "Davos diskless environment built successfuly"
