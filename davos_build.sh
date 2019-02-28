#!/bin/bash
set -e


apt install curl -y

# Edit these line to update slitaz version
version="buster"
base_url="https://agents.siveo.net/squashfs"

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

# Move needed files to build dir and target dir
#cp slitaz/boot/bzImage64 target/
cp filesystem.squashfs  build/

cd build

# Decompressing the rootfs
unsquashfs filesystem.squashfs  && rm -fv ../filesystem.squashfs && rm -fv filesystem.squashfs
cd squashfs-root
#sed 's/MULTICAST_ALL_ADDR="224.0.0.1"/MULTICAST_ALL_ADDR="239.254.1.255"/' -i etc/drbl/drbl-ocs.conf

# Run deploy script to patch the filesystem
${davos_src}/deploy_filesystem.sh ${davos_src}

cd ..
# Recompress the new rootfs
mksquashfs squashfs-root/ fs.squashfs -noappend -always-use-fragments
cp squashfs-root/initrd.img ../target/
rm -r squashfs-root/
cd ..

# Move built files to their final dir
mkdir -p ${davos_src}/var/lib/pulse2/imaging/davos/
mv -f target/* ${davos_src}/var/lib/pulse2/imaging/davos/
mv build/fs.squashfs ${davos_src}/var/lib/pulse2/imaging/davos/

# Remove temp dir
rm -r $tempdir

echo "Davos diskless environment built successfuly"
