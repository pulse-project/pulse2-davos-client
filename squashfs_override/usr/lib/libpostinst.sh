# -*- coding: utf-8; -*-
#
# (c) 2005-2007 Ludovic Drolez, Linbox FAS
# (c) 2010 Mandriva, http://www.mandriva.com
#
# $Id$
#
# This file is part of Pulse 2.
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
# along with Pulse 2.  If not, see <http://www.gnu.org/licenses/>.


#
# Strip the 2 leading directories of a Win/DOS path
#
Strip2 ()
{
    echo $1 | cut -f 3- -d \\
}

#
# Copy a sysprep configuration to file and substitute the hostname
# Example: CopySysprepInf /revoinfo/sysprep.inf
# If the extension is .xml it assumes that the target is Windows Vista/Seven/2008
# If the extension is .inf the file will be copied to c:\Sysprep.inf (Windows XP)
#
CopySysprepInf ()
{
    SYSPREP_FILE=$1
    WINDIR=$(find /mnt -maxdepth 1 -type d -iname windows)
    WINSYSDIR=$(find $WINDIR -maxdepth 1 -type d -iname system32)

    # Warning ! There's a ^M after $HOSTNAME for DOS compatibility
    SYSPREP=sysprep
    [ -d /mnt/Sysprep ] && SYSPREP=Sysprep

    if [ ${SYSPREP_FILE#*.} == "xml" ]; then
        rm -f $WINSYSDIR/sysprep/*.xml
        sed -e "s/<ComputerName>.*$/<ComputerName>${HOSTNAME}<\/ComputerName>"`echo -e "\015"`"/" < $SYSPREP_FILE > /mnt/Windows/Panther/unattend.xml
    fi

    if [ ${SYSPREP_FILE#*.} == "inf" ]; then
        rm -f /mnt/$SYSPREP/[Ss]ysprep.inf
        sed -e "s/^[	]*[Cc]omputer[Nn]ame[^\n\r]*/ComputerName=$HOSTNAME"`echo -e "\015"`"/" < $SYSPREP_FILE >/mnt/$SYSPREP/Sysprep.inf
    fi
}

#
# Return the name of the Nth partition
#
GetNPart ()
{
  # Check if parameter is a real number
  if echo "${1}" | grep -q "^[0-9]\+" ;then
    # Check if ${1} is lower or equal than numbers of partitions and not zero
    partnumber=`grep '[a-z]\+[0-9]\+$' /proc/partitions | grep -v ram | grep -v loop | wc -l | sed 's/ //g'`
    if [ ${1} -le ${partnumber} ] && [ ${1} -gt 0 ]; then
      # Get partition name according to it's number
      partname=`grep '[a-z]\+[0-9]\+$' /proc/partitions | grep -v ram | grep -v loop | head -n ${1} | tail -n 1 | awk '{print $NF}'`
      #Skip sr* and loop* partitions
      echo $partname|grep 'sr\|loop' && return 1
      # Looks being a real block device ?
      if [ -b /dev/${partname} ]; then
        echo /dev/${partname}
      else
        echo "*** ERROR: partition number ${1} (resolved as ${partname}) not found"
        return 1
      fi
    else
      echo "*** ERROR: partition number ${1} invalid (from 1 to ${partnumber})"
      return 1
    fi
  else
    echo "*** ERROR: Invalid partition number (${1})"
    return 1
  fi
}

#
# Get the start sector for partition NUM on disk DISK
#
GetPartStart ()
{
    DISK=${1}
    NUM=${2}

    FS=`parted -s $DISK unit s print | grep "^[[:space:]]*${NUM}[[:space:]]\+" | sed 's/^\s\+//g' | sed 's/  */,/g' | cut -f 2 -d ,`
    echo ${FS}

}

#
# Get the filesystem type for partition NUM on disk DISK
#
GetPartFileSystem ()
{
    DISK=${1}
    NUM=${2}

    L=`parted -s $DISK unit s print | grep "^[[:space:]]*${NUM}[[:space:]]\+" | sed 's/^\s\+//g' | sed 's/  */,/g' | cut -f 6 -d ,`
    echo ${L}

}

#
# Return "yes" if the partition is bootable
#
IsPartBootable ()
{
    DISK=$1
    NUM=$2

    parted -s $DISK print | grep "^[[:space:]]*${NUM}[[:space:]]\+" | grep -q boot && echo "yes"
}

#
# Set the boot partition flag
#
SetPartBootable ()
{
    DISK=$1
    NUM=$2

    parted -s $DISK set $NUM boot on
}

#
# Resize the Nth partition
#
Resize ()
{
    NUM=$1
    SZ=$2

    P=`GetNPart $NUM`
    D=`PartToDisk $P`
    S=`GetPartStart $D $NUM`
    FS=`GetPartFileSystem $D $NUM`
    BOOT=`IsPartBootable $D $NUM`
    if [ -z $P ]; then
      echo "*** ERROR: Partition number is empty. Aborting resize."
      return 1
    elif [ -z $D ]; then
      echo "*** ERROR: Unable to find disk corresponding to partition ${P}. Aborting resize."
      return 1
    elif [ -z $S ]; then
      echo "*** ERROR: Unable to get start sector of partition ${P}. Aborting resize."
      return 1
    elif [ -z $FS ]; then
      echo "*** ERROR: Unable to identify filesystem of partition ${FS}. Aborting resize."
      return 1
    else
      if [ "$FS" = "ntfs" ]; then
        parted -s $D rm $NUM mkpart primary ntfs $S $SZ
        [ "$BOOT" = "yes" ] && SetPartBootable $D $NUM
        yes|ntfsresize -f $P
        ntfsresize --info --force $P
      else
        parted -s $D resize $NUM $S $SZ
      fi
    fi
}

#
# Maximize the Nth partition
#
ResizeMax ()
{
    Resize $1 100%
}

#
# return the disk device related to the part device
# /dev/hda1 -> /dev/hda
#
PartToDisk ()
{
    echo $1|
    sed 's/[0-9]*$//'
}

#
# Mount the target device as /mnt
#
Mount ()
{
  NUM=$1
  P=`GetNPart $NUM`
  
  mountdisk $P
}

#
# Try to find and mount the "system" disk
#
MountSystem ()
{
  # Number of partitions
  partnumber=`grep '[a-z]\+[0-9]\+$' /proc/partitions | grep -v ram | grep -v loop | wc -l | sed 's/ //g'`
  for num in `seq 1 ${partnumber}`; do
    Mount ${num}
    # Does it looks like being a Windows ?
    if [[ -n `find /mnt -maxdepth 1 -type d -iname windows` ]]; then
      echo "*** INFO: WINDOWS found on partition number ${num}"
      return 0
    # Or some Unix disk ?
    elif [ -d /mnt/bin ] && [ -d /mnt/etc ] && [ -d /mnt/var ] && [ -d /mnt/home ]; then
      echo "*** INFO: Unix found on partition number ${num}"
      return
    fi
  done
  # Got there ? Nothing found...
  echo "*** ERROR: Unable to find a system disk"
  umount /mnt >/dev/null 2>&1
  return 1
}

#
# Try to deploy Pulse2 agents on both Windows and Unix (ssh key only)
#
DeployAgents ()
{
if MountSystem; then
  # Windows drive
  if [[ -n `find /mnt -maxdepth 1 -type d -iname windows` ]]; then
    echo "*** INFO: Starting agents deployment for Windows"
    # Copy nin-interactive agent pack installer
    cp /opt/winutils/pulse2-win32-agents-pack-noprompt.exe /mnt
    # Create an install script
    cat << EOF > "/mnt/mandriva_pulse2_agents.bat"
"%SystemDrive%\pulse2-win32-agents-pack-noprompt.exe"
del "%SystemDrive%\pulse2-win32-agents-pack-noprompt.exe"
IF EXIST "%SystemDrive%\Program Files\Mandriva\OpenSSH\bin\dellater.exe" "%SystemDrive%\Program Files\Mandriva\OpenSSH\bin\dellater.exe" "%SystemRoot%\system32\GroupPolicy\Machine\Scripts\scripts.ini"
IF EXIST "%SystemDrive%\Program Files (x86)\Mandriva\OpenSSH\bin\dellater.exe" "%SystemDrive%\Program Files (x86)\Mandriva\OpenSSH\bin\dellater.exe" "%SystemRoot%\system32\GroupPolicy\Machine\Scripts\scripts.ini"
del "%~f0"
EOF
    unix2dos /mnt/mandriva_pulse2_agents.bat
    # Call the Local GPO helper
    AddNewStartupGroupPolicy "C:\\mandriva_pulse2_agents.bat"
  # Regular Unix/Linux drive
  elif [ -d /mnt/root ]; then
    echo "*** INFO: Copying SSH key for Unix/Linux"
    mkdir -p /mnt/root/.ssh
    touch /mnt/root/.ssh/authorized_keys
    chown root:root /mnt/root/.ssh/authorized_keys
    chmod 644 /mnt/root/.ssh/authorized_keys 
    cat /opt/linuxutils/id_rsa.pub >> /mnt/root/.ssh/authorized_keys
    if [ ${?} -eq 0 ]; then
      echo "*** INFO: SSH keys successfully installed"
      return 0
    else
      echo "*** ERROR: Unexpected error"
      return 1
    fi
    # Install OCS agent from rc.local
    if [ -f /mnt/etc/rc.local ]; then
      cp /opt/linuxutils/install_mandriva_pulse2_inventory.sh /mnt/root/
      echo "*** INFO: rc.local found, trying to register installation of inventory agent"
      # Looks like a RPM one
      if grep -q "touch /var/lock/subsys/local" /mnt/etc/rc.local; then
        sed -i 's!^touch /var/lock/subsys/local$![ -x /root/install_mandriva_pulse2_inventory.sh ] && /root/install_mandriva_pulse2_inventory.sh!' /mnt/etc/rc.local
        echo 'touch /var/lock/subsys/local' >> /mnt/etc/rc.local
      # Look like being Debian based
      elif grep -q "exit 0" /mnt/etc/rc.local; then
        sed -i 's!^exit 0$![ -x /root/install_mandriva_pulse2_inventory.sh ] && /root/install_mandriva_pulse2_inventory.sh!' /mnt/etc/rc.local
        echo 'exit 0' >> /mnt/etc/rc.local
      else
        "***ERROR: rc.local found but unknown"
        return 1
      fi
    else
      echo "*** ERROR: I can't find /etc/rc.local, skipping inventory agent installation"
      return 1
    fi
  else
    echo "*** ERROR: Something wrong happened. Unable to find Windows or /root directories"
    return 1
  fi
else
  echo "*** ERROR: MountSystem hasn't been able to find the system disk"
  return 1
fi
}

#
# Update gpt.ini (Local GPO) to increase its version
#
UpdateGroupPolicyGptIni ()
{

if [[ -n `find /mnt -maxdepth 1 -type d -iname windows` ]]; then
  WINDIR=$(find /mnt -maxdepth 1 -type d -iname windows)
  WINSYSDIR=$(find $WINDIR -maxdepth 1 -type d -iname system32)
  GPTINIPATH="$WINSYSDIR/GroupPolicy/gpt.ini"
  # Already exists ?
  if [ -f "${GPTINIPATH}" ]; then
    # Get current version
    GPTVERSION=`grep '^Version=' "${GPTINIPATH}" | tail -n 1 | cut -d= -f2 | sed 's/\s//g'`
    if echo "${GPTVERSION}" | grep -q "^[0-9]\+" ;then
      # Increase by one
      NEWGPTVERSION=$((${GPTVERSION}+1))
      sed -i "s/Version=${GPTVERSION}/Version=${NEWGPTVERSION}/" "${GPTINIPATH}"
      echo "*** INFO: gpt.ini updated from version ${GPTVERSION} to ${NEWGPTVERSION}"
    else
      # Uh ?
      echo "*** ERROR: gpt.ini already exists but I haven't been able to figure out current version"
      return 1
    fi
  else
    echo "*** INFO: gpt.ini doens't exist yet. Creating a new one"
    mkdir -p $WINSYSDIR/GroupPolicy
    touch "${GPTINIPATH}"
    echo '[General]' >> "${GPTINIPATH}"
    echo 'gPCMachineExtensionNames=[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}]' >> "${GPTINIPATH}"
    echo 'Version=1' >> "${GPTINIPATH}"
    unix2dos "${GPTINIPATH}"
  fi
else
  echo "*** ERROR: Unable to find Windows directory, is the disk mounted ?"
  return 1
fi
}

#
# AddNewStartupGroupPolicy()
# $1 = scriptname
#
AddNewStartupGroupPolicy ()
{

SCRIPTNAME=${1}

if [[ -n `find /mnt -maxdepth 1 -type d -iname windows` ]]; then
  WINDIR=$(find /mnt -maxdepth 1 -type d -iname windows)
  WINSYSDIR=$(find $WINDIR -maxdepth 1 -type d -iname system32)
  SCRIPTINIPATH="$WINSYSDIR/GroupPolicy/Machine/Scripts/scripts.ini"
  # Already exists ?
  if [ -f "${SCRIPTINIPATH}" ]; then
    # UTF-16 stuff, can't be used...
    iconv -f UTF-16 -t UTF-8 "${SCRIPTINIPATH}" > "${SCRIPTINIPATH}.utf8"
    # Get current script number
    SCRIPTNUMBER=`grep '^[0-9]\+CmdLine' "${SCRIPTINIPATH}.utf8" | tail -n 1 | sed 's!^\([0-9]\+\).*$!\1!'`
    if echo "${SCRIPTNUMBER}" | grep -q "^[0-9]\+" ;then
      # Increase by one
      NEWSCRIPTNUMBER=$((${SCRIPTNUMBER}+1))
      echo '' >> "${SCRIPTINIPATH}.utf8"
      echo "${NEWSCRIPTNUMBER}CmdLine=${SCRIPTNAME}" >> "${SCRIPTINIPATH}.utf8"
      echo "${NEWSCRIPTNUMBER}Parameters=" >> "${SCRIPTINIPATH}.utf8"
      # Back to UTF-16
      iconv -f UTF-8 -t UTF-16 "${SCRIPTINIPATH}.utf8" > "${SCRIPTINIPATH}"
      rm "${SCRIPTINIPATH}.utf8"
      echo "*** INFO: ${SCRIPTNAME} added as startupscript number ${NEWSCRIPTNUMBER}"
      UpdateGroupPolicyGptIni
    else
      # Uh ?
      echo "*** ERROR: scripts.ini already exists but I haven't been able to figure out current last script number"
      return 1
    fi
  else
    echo "*** INFO: scripts.ini doens't exist yet. Creating a new one"
    mkdir -p $WINSYSDIR/GroupPolicy/Machine/Scripts
    touch "${SCRIPTINIPATH}.utf8"
    echo '' >> "${SCRIPTINIPATH}.utf8"
    echo '[Startup]' >> "${SCRIPTINIPATH}.utf8"
    echo "0CmdLine=${SCRIPTNAME}" >> "${SCRIPTINIPATH}.utf8"
    echo '0Parameters=' >> "${SCRIPTINIPATH}.utf8"
    unix2dos "${SCRIPTINIPATH}.utf8"
    # Convert to UTF-16
    iconv -f UTF-8 -t UTF-16 "${SCRIPTINIPATH}.utf8" > "${SCRIPTINIPATH}"
    rm "${SCRIPTINIPATH}.utf8"
    echo "*** INFO: ${SCRIPTNAME} added as startupscript number 0"
    UpdateGroupPolicyGptIni
  fi
else
  echo "*** ERROR: Unable to find Windows directory, is the disk mounted ?"
  return 1
fi
}

#
# newsid.exe based commands
#
ChangeSID ()
{
    unix2dos <<EOF >/mnt/mandriva_newsid_pulse2.bat
IF EXIST "%SystemRoot%\SysWOW64" REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Wow6432Node /f
"%SystemDrive%\newsid.exe" /a
del "%SystemDrive%\newsid.exe"
IF EXIST "%SystemDrive%\Program Files\Mandriva\OpenSSH\bin\dellater.exe" "%SystemDrive%\Program Files\Mandriva\OpenSSH\bin\dellater.exe" "%SystemRoot%\system32\GroupPolicy\Machine\Scripts\scripts.ini"
IF EXIST "%SystemDrive%\Program Files (x86)\Mandriva\OpenSSH\bin\dellater.exe" "%SystemDrive%\Program Files (x86)\Mandriva\OpenSSH\bin\dellater.exe" "%SystemRoot%\system32\GroupPolicy\Machine\Scripts\scripts.ini"
del "%~f0"
EOF
    cp /opt/winutils/newsid.exe /mnt/
    AddNewStartupGroupPolicy "C:\\mandriva_pulse2_newsid.bat"
}

ChangeSIDAndName ()
{
    unix2dos <<EOF >/mnt/mandriva_pulse2_newsidandname.bat
IF EXIST "%SystemRoot%\SysWOW64" REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Wow6432Node /f
"%SystemDrive%\newsid.exe" /a /d 30 ${HOSTNAME}
del "%SystemDrive%\newsid.exe"
IF EXIST "%SystemDrive%\Program Files\Mandriva\OpenSSH\bin\dellater.exe" "%SystemDrive%\Program Files\Mandriva\OpenSSH\bin\dellater.exe" "%SystemRoot%\system32\GroupPolicy\Machine\Scripts\scripts.ini"
IF EXIST "%SystemDrive%\Program Files (x86)\Mandriva\OpenSSH\bin\dellater.exe" "%SystemDrive%\Program Files (x86)\Mandriva\OpenSSH\bin\dellater.exe" "%SystemRoot%\system32\GroupPolicy\Machine\Scripts\scripts.ini"
del "%~f0"
EOF
    cp /opt/winutils/newsid.exe /mnt/
    AddNewStartupGroupPolicy "C:\\mandriva_pulse2_newsidandname.bat"
}
