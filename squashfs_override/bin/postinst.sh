#!/bin/sh
#
# (c) 2003-2007 Linbox FAS, http://linbox.com
# (c) 2008-2010 Mandriva, http://www.mandriva.com
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
# Launch all postinstall scripts
#
# two cases : 
# "file"   : we "just" source it
# "folder" : launch "run-parts" over it

# Functions which can be interesting in the postinst scripts

# try either to source $basename, or to run-parts over $basename.d

. /usr/lib/revolib.sh
. /opt/lib/libpostinst.sh

getmac

run_script() {
    basename="$1"
    message="$2"

    # executable
    if [ -x $basename ]
    then
	pretty_warn "Executing $message post-installation script"
	/bin/revosendlog 6
        $basename
	/bin/revosendlog 7
    fi

    # not executable, source it
    if [ -r $basename ]
    then
	pretty_warn "Executing $message post-installation script"
	/bin/revosendlog 6
	set -v
        . $basename
	set +v
	/bin/revosendlog 7
    fi

    # not executable, run-part it
    if [ -d $basename.d ]
    then
	pretty_warn "Executing $message post-installation script"
	/bin/revosendlog 6
	/bin/run-parts -t $basename.d
	/bin/run-parts $basename.d
	/bin/revosendlog 7
    fi

    # Wait a few seconds so we'd be able to read what's going on
    /bin/sleep 5
}

# if we're running postinst only mode, skip the regular image behavior
if postinst_only; then
   run_script "/opt/scripts/`postinst_only_script`" "postinst"
else
    # as a side note:
    # under LRS env, /revoinfo corresponds
    #    either to the <revoboot>/images/$MAC folder when doing shared backup restore
    #    or to the <revoboot>/images folder when doing private backup restore / single postinst
    # under Pulse 2, /revoinfo always corresponds to the <pulse2>/computers/<computer_uuid> folder
    # 
    # the computer preinst script may run:
    # <pulse2>/computers/<computer_uuid>/preinst.d (pulse 2)
    # <revoboot>/images/$MAC/preinst (LRS/shared)
    # <revoboot>/images/preinst (LRS/single)
    run_script "/revoinfo/preinst" "pre"

    # the image postinst script
    run_script "/revosave/postinst" "image"

    # the computer postinst script may run
    # <pulse2>/computers/<computer_uuid>/postinst.d (pulse 2)
    # <revoboot>/images/$MAC/postinst (LRS/shared)
    # <revoboot>/images/postinst (LRS/single)
    run_script "/revoinfo/postinst" "computer"

    # old LRS compatibility stuff
   [ -z "$MAC" ] && exit 0
   [ -e "/revoinfo/$MAC/preinst" ] && run_script "/revoinfo/$MAC/preinst" "preinst"
   [ -e "/revoinfo/$MAC/postinst" ] && run_script "/revoinfo/$MAC/postinst" "postinst"
fi
