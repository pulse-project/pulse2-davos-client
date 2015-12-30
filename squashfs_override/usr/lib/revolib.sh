# (c) 2010 Mandriva, http://www.mandriva.com
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
# Factorization lib
#

pretty_print() {
    echo -en "$1"
}

pretty_white () {
    pretty_print "[1;37m"
    pretty_print "$1"
    pretty_print "[0m"
}

pretty_red () {
    pretty_print "[1;31m"
    pretty_print "$1"
    pretty_print "[0m"
}

pretty_green () {
    pretty_print "[1;32m"
    pretty_print "$1"
    pretty_print "[0m"
}

pretty_orange() {
    pretty_print "[1;33m"
    pretty_print "$1"
    pretty_print "[0m"
}

pretty_blue() {
    pretty_print "[1;34m"
    pretty_print "$1"
    pretty_print "[0m"
}

pretty_error() {
    pretty_red "==> $1\n"
}

pretty_warn() {
    pretty_orange "==> $1\n"
}

pretty_info() {
    pretty_white "==> $1\n"
}

pretty_try() {
    pretty_white "==> $1 ... "
}

pretty_success() {
    pretty_green " OK\n"
}

pretty_failure() {
    pretty_red " KO\n"
}

return_success_or_failure() {
    if [ "$1" -eq "0" ]
    then
	if [ ! -z "$2" ]
	then
	    pretty_green "$2\n"
	else
	    pretty_success
	fi
	return 0
    else
	pretty_failure
	return 1
    fi
}

fatal_error() {
    msg="$1"
    whiptail \
	--title 'Fatal Error' \
	--msgbox "   It seems that something weird happened : \n\n\n$msg\n\n\n  Please contact your system administrator.\n\n          Press any key to reboot." \
	16 60
    /sbin/reboot
}

probe_server() {
    srv=$1

    ret=0
    tries=10
    interval=1

    pretty_try "Probing server $srv"
    while [ "$tries" -ne "0" ]
    do
	ping -c 1 "$srv" -q 2>/dev/null 1>/dev/null
	[ "$?" -eq "0" ] && ret=0 && break
	echo -en "."
	tries=$(($tries - 1 ))
	sleep $interval
    done
    return_success_or_failure $ret
    return $ret
}

server_command_loop() {
    question=$1
    mac=$2
    srv=$3

    tries=60
    interval=1

    while [ "$tries" -ne "0" ]
    do
	ANSWER=`echo -en "$question\00Mc:$mac" | nc -p 1001 -w 2 $srv 1001 2>/dev/null`
	exitcode=$?
	status=0 # preset exit code
	[ "$exitcode" -eq "0" ] && [ ! -z "$ANSWER" ] && [ ! "$ANSWER" == "ERROR" ] && break
	# LRS : don't care if no answer was given
	[ "$exitcode" -eq "0" ] && lrs && break
	status=1
	echo -en "."
	tries=$(($tries - 1 ))
	sleep $interval
    done
    export ANSWER
    return $status
}

done_image() {
    uuid="$1"
    mac=$2
    srv=$3

    pretty_try "Saving the new image"
    server_command_loop "\0355$uuid\000" $mac $srv
    return_success_or_failure $?
}

set_default() {
    item=$1
    mac=$2
    srv=$3

    server_command_loop "\0315\00$item" $mac $srv || pretty_warn "Failed to switch default menu item"
}

get_image_uuid() {
    type=$1
    mac=$2
    srv=$3

    pretty_try "Asking for an image UUID"
    server_command_loop "\0354$type" $mac $srv
    return_success_or_failure $? $ANSWER
}

get_computer_hostname() {
    mac=$1
    srv=$2

    pretty_try "Asking for my hostname"
    server_command_loop "\0032" $mac $srv
    return_success_or_failure $? $ANSWER
}

get_computer_uuid() {
    mac=$1
    srv=$2

    pretty_try "Asking for my UUID"
    server_command_loop "\0033" $mac $srv
    return_success_or_failure $? $ANSWER
}

send_log() {
    log=$1
    mac=$2
    srv=$3

    # Keep quiet unless something goes wrong
    server_command_loop "L$log" $mac $srv || pretty_warn "Failed to send log"
}

get_rdate() {
    srv=$1

    pretty_try "Getting current time from $SRV"
    rdate $srv 2>/dev/null 1>/dev/null
    return_success_or_failure $? "`date '+%Y-%m-%d %H:%M:%S'`"
}

check_nfs() {
    sip=$1

    pretty_try "Checking NFS service on $sip"

    RPCINFO=`rpcinfo -p $sip`

    logger "rpcinfo:"
    logger "$RPCINFO"

    if echo "$RPCINFO" | grep -q nfs
    then
	pretty_success
	return 0
    else
	pretty_failure
	return 1
    fi
}

lrs () {
    grep -vq "revobase=" /proc/cmdline
}

standalone() {
    grep -q "revosavedir=/cdrom" /proc/cmdline
}

# postinst enabled if revopost keyword is found
postinst_enabled() {
    grep -q "revopost" /proc/cmdline
}

# restore mode if revorestoreXXX on command line
restore_mode() {
    grep -q "revorestore" /proc/cmdline
}

# backup mode if no restore mode and postinst disabled
backup_mode() {
    postinst_enabled || restore_mode || return 0
    false
}

dev_mode() {
    grep -q "revodebug" /etc/cmdline
}

getmac() {
    MAC=`cat /etc/shortmac`
    export MAC
}

# postinstallation only (bootservice like)
postinst_only() {
    grep -q "revopostscript=" /etc/cmdline
}

postinst_only_script() {
    grep "revopostscript=" /etc/cmdline | sed 's|.*revopostscript=\([^ ]*\).*|\1|'
}
