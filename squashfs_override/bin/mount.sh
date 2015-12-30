#!/bin/sh
#
# (c) 2003-2007 Linbox FAS, http://linbox.com
# (c) 2008-2009 Mandriva, http://www.mandriva.com
#
# $Id$
#
# This file is part of Pulse 2, http://pulse2.mandriva.org
#
# Pulse 2 is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Pulse 2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Pulse 2; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Mount helper script
#

TYPE=nfs
. /usr/lib/revolib.sh
. /etc/netinfo.sh

# CDROM restoration: already mounted
grep -q revosavedir=/cdrom /etc/cmdline && exit 0

# get the mac address
MAC=`cat /etc/shortmac`

# get server IP address
SRV=$Next_server


# prefix is not empty : Pulse 2 mode, else LRS mode
MODE="pulse2"

# get mount prefix on server
PREFIX=`grep revobase /etc/cmdline | sed 's|.*revobase=\([^ ]*\).*|\1|'`
# default values : everything is initialized at '/', then mount-$TYPE.sh will do some cleanup
SAVEDIR='/'  # the folder which contains the image itself
INFODIR='/'  # the folder which contains target-related files
OPTDIR='/'   # additional software

if [ "$MODE" == 'pulse2' ]
then
    # get the computer UUID
    COMPUTER_UUID=`cat /etc/COMPUTER_UUID`
    [ -z "$COMPUTER_UUID" ] && fatal_error "I did not received a Computer UUID from $SRV"
    
    # get the base opt dir
    OPTDIR=`grep revooptdir /etc/cmdline | sed 's|.*revooptdir=\([^ ]*\).*|\1|'`
    [ -z "$OPTDIR" ] && postinst_enabled && fatal_error "I did not received OPTDIR from $SRV"
    OPTDIR="/$OPTDIR"

    # skip if we're running a standalone postinstall script
    if postinst_only; then
      POSTINSTONLYSCRIPT=`postinst_only_script`
      [ -z "$POSTINSTONLYSCRIPT" ] && fatal_error "I'm running in postinstall only mode but haven't received the script name"
    else
      # get the base image dir
      SAVEDIR=`grep revosavedir /etc/cmdline | sed 's|.*revosavedir=\([^ ]*\).*|\1|'`
      [ -z "$SAVEDIR" ] && fatal_error "I did not received SAVEDIR from $SRV"

      # get the base info dir
      INFODIR=`grep revoinfodir /etc/cmdline | sed 's|.*revoinfodir=\([^ ]*\).*|\1|'`
      [ -z "$INFODIR" ] && fatal_error "I did not received INFODIR from $SRV"
      INFODIR="/$INFODIR/$COMPUTER_UUID"

      # get the image UUID, if we are saving or backuping
      IMAGE_UUID=`cat /etc/IMAGE_UUID 2>/dev/null`
      [ -z "$IMAGE_UUID" ] && IMAGE_UUID=`grep revoimage /etc/cmdline | sed 's|.*revoimage=\([^ ]*\).*|\1|'`
      [ -z "$IMAGE_UUID" ] && fatal_error "I did not received an Image UUID from $SRV"
      SAVEDIR="/$SAVEDIR/$IMAGE_UUID"
    fi
fi

pretty_warn "Mounting Storage Directories"
while ! mount-$TYPE.sh "$SRV" "$PREFIX" "$SAVEDIR" "$INFODIR" "$OPTDIR"
do
    sleep 1
done

# Restore => mount a tmpfs
if grep -q revorestore /etc/cmdline
then
    pretty_info "Mounting a 96 MB tmpfs"
    mount -t tmpfs -o size=96M tmpfs /tmpfs
fi

cat /proc/mounts | logger
