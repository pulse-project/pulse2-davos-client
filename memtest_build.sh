#!/bin/bash

# =============================================================================
# memtest iso zip url
url="http://www.memtest86.com/downloads/memtest86-iso.zip"
# =============================================================================

set -e
olddir=$(pwd)
tmpdir=$(mktemp -d)

cd $tmpdir
echo "Downloading MEMTEST86 ..."
wget -qO memtest86.zip $url
unzip memtest86.zip
7z x *.iso
mv -f $(find -iname 'memtest' -type f) $olddir/var/lib/pulse2/imaging/davos/memtest
cd $olddir && rm -rf $tmpdir
