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
# Mount helper script for NFS

SIP="$1"
PREFIX="$2"
SAVEDIR="$3"
INFODIR="$4"
OPTDIR="$5"

. /usr/lib/revolib.sh
# Get DHCP options
. /etc/netinfo.sh

[ -n "$Option_177" ] && SIP=`echo $Option_177|cut -d : -f 1`

sleep 1
check_nfs $SIP || exit 1

# NFS base options
NFSOPT="hard,intr,ac,nfsvers=3,async,nolock"

# Get NFS proto
if grep -q 'revoproto=nfsudp' /etc/cmdline; then
    NFSOPT="$NFSOPT,proto=udp"
    pretty_info "Using NFS over UDP"
else
    if echo "$RPCINFO" | grep nfs | grep -q tcp; then
	NFSOPT="$NFSOPT,proto=tcp"
	pretty_info "Using NFS over TCP"
    else
	NFSOPT="$NFSOPT,proto=udp"
	pretty_info "Using NFS over UDP"
    fi
fi

# Get NFS block size
if grep -q 'revonfsbsize' /etc/cmdline; then
    NFSBSIZE=`sed -e 's/.*revonfsbsize=\([^ ]*\).*/\1/' < /etc/cmdline`
    NFSOPT="$NFSOPT,rsize=$NFSBSIZE,wsize=$NFSBSIZE"
    pretty_warn "Using blocks of $NFSBSIZE bytes"
else
    pretty_info "Autonegociating block size"
fi

# Full NFS bypass, if needed
if grep -q 'revonfsopts' /etc/cmdline; then
    NFSOPT=`sed -e 's/.*revonfsopts=\([^ ]*\).*/\1/' < /etc/cmdline`
    pretty_warn "Bypassing NFS options : $NFSOPT"
fi

pretty_try "NFS options"
pretty_blue "$NFSOPT\n"

if [ -z "$Option_177" ]; then
    if ! postinst_only; then
        pretty_try "Using as backup dir"
        pretty_blue "$SIP:$PREFIX\n"

        if ! [ "$INFODIR" == '/' ]; then
            if ! grep -q " /revoinfo " /proc/mounts; then
                pretty_try "Mounting /revoinfo"
                    if mount -t nfs $SIP:$PREFIX$INFODIR /revoinfo -o $NFSOPT 2>/dev/null; then
                        pretty_success
                    else
                        pretty_failure
                        exit 1
                    fi
            fi
        else
            pretty_warn "Can't find /revoinfo"
            exit 1
        fi

        if ! [ "$SAVEDIR" == '/' ]; then
            if ! grep -q " /revosave " /proc/mounts; then
                pretty_try "Mounting /revosave"
                if mount -t nfs $SIP:$PREFIX$SAVEDIR /revosave -o $NFSOPT 2>/dev/null; then
                    pretty_success
                else
                    pretty_failure
                    exit 1
                fi
            fi
        else # not mandatory, only useful in restore mode
            pretty_info "Not mounting /revosave"
        fi
    else # not mandatory in postinstall only mode
        pretty_info "Not mounting /revoinfo"
        pretty_info "Not mounting /revosave"
    fi

    if postinst_enabled
    then
	if ! grep -q " /opt " /proc/mounts
	then
	    pretty_try "Mounting /opt"
	    if mount -t nfs  $SIP:$PREFIX$OPTDIR /opt -o $NFSOPT 2>/dev/null
	    then
		pretty_success
	    else
		pretty_failure
		exit 1
	    fi
	fi
    else # not mandatory, only useful in postinst mode
	pretty_info "Not mounting /opt"
    fi

else
    pretty_info "Using Option 177 as backup dir :"
    pretty_blue "$Option_177\n"

    if ! postinst_only; then
        if ! [ "$INFODIR" == '/' ]; then
            if ! grep -q " /revoinfo " /proc/mounts; then
                pretty_try "Mounting /revoinfo"
                if mount -t nfs $Option_177$INFODIR /revoinfo -o $NFSOPT 2>/dev/null; then
                    pretty_success
                else
                    pretty_failure
                    exit 1
                fi
            fi
        else
            pretty_warn "Can't find /revoinfo"
            exit 1
        fi

        if ! [ "$SAVEDIR" == '/' ]; then
            if ! grep -q " /revosave " /proc/mounts; then
                pretty_try "Mounting /revosave"
                if mount -t nfs $Option_177$SAVEDIR /revosave -o $NFSOPT 2>/dev/null; then
                    pretty_success
                else
                    pretty_failure
                    exit 1
                fi
            fi
        else # not mandatory, only useful in restore mode
            pretty_info "Not mounting /revosave"
        fi
    else # not mandatory in postinstall only mode
        pretty_info "Not mounting /revoinfo"
        pretty_info "Not mounting /revosave"
    fi

    if postinst_enabled
    then
	if ! grep -q " /opt " /proc/mounts
	then
	    pretty_try "Mounting /opt"
	    if mount -t nfs $Option_177$OPTDIR /opt -o $NFSOPT 2>/dev/null
	    then
		pretty_success
	    else
		pretty_failure
		exit 1
	    fi
	fi
    else # not mandatory, only useful in postinst mode
	pretty_info "Not mounting /opt"
    fi

fi
