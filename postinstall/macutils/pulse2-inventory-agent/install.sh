#!/bin/sh

# Set LRS' server FQDN here, otherwise it will use it's IP when deploying through LSC
LRSFQDN=""

### FIX PHP PCRE BACKTRACK LIMIT IF NEEDED
# Get PHP major version
PHP_VER=`php -v | head -n 1 | cut -f2 -d' ' | cut -f1-2 -d'.'`

if [ `echo ${PHP_VER} | cut -f1 -d'.'` -ge 5 ]; then
  if [ `echo ${PHP_VER} | cut -f2 -d'.'` -ge 2 ]; then
    echo "PHP 5.2 or greater detected: pcre.backtrack_limit fix needed."

    # Figure out if php.ini exists. If not try to initialize one with php.ini.default
    if [ ! -e /etc/php.ini ]; then
      if [ ! -e /etc/php.ini.default ]; then
        echo "Neither /etc/php.ini nor /etc/php.ini.default exists. Fatal error."
        exit 1
      else
        echo "No /etc/php.ini found. Initializing a new one from /etc/php.ini.default."
        cp /etc/php.ini.default /etc/php.ini
      fi
    fi
    echo "/etc/php.ini is present."

    # Backup original php.ini
    cp /etc/php.ini /etc/php.ini.bak

    # Get current pcre.backtrack_limit
    PCRE_BACKTRACK_LIMIT=`grep -E '^[[:space:]]*pcre.backtrack_limit=' /etc/php.ini | cut -f2 -d'='`
    if [ -z ${PCRE_BACKTRACK_LIMIT} ]; then
      # This is PHP default
      PCRE_BACKTRACK_LIMIT=100000
    fi
    echo "Current pcre.backtrack_limit is ${PCRE_BACKTRACK_LIMIT}."

    # Fix it if it's lower than 1000000
    if [ ${PCRE_BACKTRACK_LIMIT} -lt 1000000 ]; then
      echo "This is not enought, upgrading to 1000000."
      sed 's!^\s*;*\s*pcre.backtrack_limit=.*$!pcre.backtrack_limit=1000000!' /etc/php.ini > /etc/php.ini.new
      mv /etc/php.ini.new /etc/php.ini
    fi
  else
    echo "PHP lower than 5.2 detected. No fix needed."
  fi
fi
### FIX PHP PCRE BACKTRACK LIMIT IF NEEDED - END


# Get server IP address
IP=`echo $SSH_CLIENT | cut -f 1 -d \ `

# Install pkg
installer -verbose -target / -pkg ocs_mac_agent.pkg

# Fix ocs conf file with the right server IP/FQDN address
if [ ! -z "${LRSFQDN}" ]; then
  SERVER="${LRSFQDN}"
else
  SERVER="${IP}"
fi
echo "Using ${SERVER} as LRS server IP or FQDN."
cat /etc/ocsinventory-client/ocsinv.conf | sed "s!<OCSFSERVER>.*</OCSFSERVER>!<OCSFSERVER>${SERVER}</OCSFSERVER>!" > /etc/ocsinventory-client/ocsinv.conf.new
mv /etc/ocsinventory-client/ocsinv.conf.new /etc/ocsinventory-client/ocsinv.conf

# Fix Could not find $in_nodeName in system_profiler XML.  Corrupted output? error on 10.3 without SATA
patch /usr/local/sbin/ocs_mac_agent.php < 000-OsX_10.3_without_sata_SPSerialATADataType_fix.patch
# Could not find SPSoftwareDataType in system_profiler XML.  Corrupted output? (G5 running 10.3)
patch /usr/local/sbin/ocs_mac_agent.php < 001-IDE_Disks_inventory_broken_on_G5_10.3.x.patch
# Add OSX 10.6 (Snow Leopard) support
patch /usr/local/sbin/ocs_mac_agent.php < 002-OsX_10.6_support.patch
# Fix warnings on PHP >= 5.3
patch /usr/local/sbin/ocs_mac_agent.php < 003-Fix_warnings_on_php_5.3.patch
# Remove useless debug output
patch /usr/local/sbin/ocs_mac_agent.php < 004-Disable_useless_debug_output.patch

# Install periodic run script
cp ocs_mac_agent_periodic.sh /usr/local/sbin
chmod 755 /usr/local/sbin/ocs_mac_agent_periodic.sh
# Current date (hour only)
# Compute now - 10 hours, so an inventory should be run soon
CURRENT_HOUR=`date '+%H'`
LAST_HOUR=`expr ${CURRENT_HOUR} - 10`
if [ ${LAST_HOUR} -lt 0 ]; then
  LAST_HOUR=`expr ${LAST_HOUR} + 24`
fi
# Create configuration file
echo "# Run inventory each PROLOG_HOUR (default each 10 hours)" >/etc/ocsinventory-client/periodic.conf
echo "PROLOG_HOUR=10" >>/etc/ocsinventory-client/periodic.conf
echo "" >>/etc/ocsinventory-client/periodic.conf
echo "# Last hour inventory was run (will be modified by the agent)" >>/etc/ocsinventory-client/periodic.conf
echo "LAST_HOUR=${LAST_HOUR}" >>/etc/ocsinventory-client/periodic.conf
# Run the script every our using cron
grep -q '/usr/local/sbin/ocs_mac_agent_periodic.sh' /etc/crontab || echo "01              *       *       *       *       root    /usr/local/sbin/ocs_mac_agent_periodic.sh" >> /etc/crontab
