#!/bin/bash
set -e

# Build davos client
[ ! -f var/lib/pulse2/imaging/davos/fs.squashfs ] && REBUILD=1
[ -z $REBUILD ] && read -p "Rebuild davos diskless environment [y/N]? " -r
[[ $REPLY =~ ^[Yy]$ ]] && REBUILD=1 && unset REPLY
[ "$REBUILD" = "1" ] && ./davos_build.sh
unset REBUILD

# Build debian package
dch -i
debuild -uc -us
echo -e "\e[1m\e[33mDon't forget to commit your changes"
