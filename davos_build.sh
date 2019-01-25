#!/bin/bash
set -e


apt install curl -y

# Edit these line to update slitaz version
version="buster"
base_url="https://agents.siveo.net/squashfs"

kernel_version="4.19"
kernel_base_url="https://cdn.kernel.org/pub/linux/kernel/v4.x"

# =============================================================
# Don't edit anything below these lines
# =============================================================

file_name=filesystem.squashfs
full_url=${base_url}/${file_name}
tempdir=$(mktemp -d)
davos_src="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [[ -f /tmp/downloads/${file_name} ]]; then
    echo "Copying ${file_name} from /tmp/downloads"
    cp /tmp/downloads/${file_name} .
else
    echo "Downloading Squashfs from ${full_url}"
    curl -O ${full_url}
fi

# Sometimes we get html instead of real file
if [[ ! -f "$file_name" ||  $(stat -c%s "$file_name") -lt 1048576 ]]; then
  echo "Failed to download the right file, check URLs"
  exit 1
fi

# Entering temp directory
cp $file_name $tempdir
cd $tempdir
mkdir build target

# Build the kernel to be used by davos
${davos_src}/kernel_build.sh ${tempdir} ${kernel_version} ${kernel_base_url}

# Move needed files to build dir and target dir
#cp slitaz/boot/bzImage64 target/
cp kernel_build/bzImage64 target/bzImage64
cp slitaz/boot/rootfs.gz build/

# Unmount iso
umount slitaz

cd build

# Decompressing the rootfs
lzcat rootfs.gz | cpio -id
rm rootfs.gz
#sed 's/MULTICAST_ALL_ADDR="224.0.0.1"/MULTICAST_ALL_ADDR="239.254.1.255"/' -i etc/drbl/drbl-ocs.conf

# Run deploy script to patch the filesystem
${davos_src}/deploy_filesystem.sh ${davos_src}

# Copy kernel modules
cp -a ../kernel_build/_modules/* .

# Recompress the new rootfs
find . -print | cpio -o -H newc | gzip -9 > ../target/rootfs.gz
cd ..

# Move built files to their final dir
mkdir -p ${davos_src}/var/lib/pulse2/imaging/davos/
mv -f target/* ${davos_src}/var/lib/pulse2/imaging/davos/

# Remove temp dir
rm -r $tempdir

# Save slitaz iso for future use
if [[ ! -d "/tmp/downloads/" ]]; then
    mkdir -p /tmp/downloads/
fi
cp ${davos_src}/${file_name} /tmp/downloads/

echo "Davos diskless environment built successfuly"
