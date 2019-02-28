#!/bin/bash
set -e


apt install curl -y

# Edit these line to update slitaz version
version="buster"
base_url="https://agents.siveo.net/squashfs"

# =============================================================
# Don't edit anything below these lines
# =============================================================

tempdir=$(mktemp -d)
davos_src="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

for file in filesystem.squashfs initrd vmlinuz; do
    if [[ -f /tmp/downloads/${file} ]]; then
        echo "Copying ${file} from /tmp/downloads"
        cp /tmp/downloads/${file} $tempdir
    else
        full_url=${base_url}/${file}
        echo "Downloading ${file} from ${full_url}"
        curl -O ${full_url}
        cp $file $tempdir
    fi
done

# Entering temp directory
cd $tempdir
mkdir build target
cp -fv {initrd,vmlinuz} target

# Move needed files to build dir and target dir
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
rm -r squashfs-root/
cd ..

# Move built files to their final dir
mkdir -p ${davos_src}/var/lib/pulse2/imaging/davos/
mv -fv target/* ${davos_src}/var/lib/pulse2/imaging/davos/
mv build/fs.squashfs ${davos_src}/var/lib/pulse2/imaging/davos/

# Remove temp dir
rm -r $tempdir

echo "Davos diskless environment built successfuly"
