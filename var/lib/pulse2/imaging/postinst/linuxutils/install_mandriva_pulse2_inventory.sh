#!/bin/bash

OCS_SERVER="<pulse-inventory-server-address>:9999"

ocs_debian() {
    # Ubuntu ?
    if `grep -q Ubuntu /etc/issue`; then
        add-apt-repository "deb http://archive.canonical.com/ubuntu/ $(lsb_release -sc) universe"
    fi
    apt-get update

    # install ocsinventory-agent in noninteractive mode
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -q -y ocsinventory-agent

    # ocsinventory config
    echo "server=$OCS_SERVER" > /etc/ocsinventory/ocsinventory-agent.cfg

    # Launch ocsinventory-agent cron
    /etc/cron.daily/ocsinventory-agent
}

ocs_fedora() {
    # install ocsinventory-agent in noninteractive mode
    yum install -q -y ocsinventory-agent

    # ocsinventory config
    echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin
OCSMODE[0]=cron
OCSSERVER[0]=$OCS_SERVER
OCSPAUSE[0]=100" > /etc/sysconfig/ocsinventory-agent

    # Launch ocsinventory-agent cron
    /etc/cron.hourly/ocsinventory-agent
}

ocs_centos() {
    # Add EPEL repository for ocsinventory-agent package
    CENTOS_VERSION=`head -n1 /etc/issue | awk {'print $3'} | cut -d. -f1`
    if [ $CENTOS_VERSION -eq 4 ] || [ $CENTOS_VERSION -eq 5 ]; then
        rpm -Uvh http://download.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
    elif [ $CENTOS_VERSION -eq 6 ] || [ $CENTOS_VERSION -eq 7 ]; then
        rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-7.noarch.rpm
    fi

    # install ocsinventory-agent in noninteractive mode
    yum install -q -y ocsinventory-agent

    # ocsinventory config
    echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin
OCSMODE[0]=cron
OCSSERVER[0]=$OCS_SERVER
OCSPAUSE[0]=100" > /etc/sysconfig/ocsinventory-agent

    # Launch ocsinventory-agent cron
    /etc/cron.hourly/ocsinventory-agent
}

if [ -f /etc/debian_version ]; then
    ocs_debian
elif [ -f /etc/fedora-release ]; then
    ocs_fedora
elif [ -f /etc/centos-release ]; then
    ocs_centos
elif [ -f /etc/redhat-release ]; then
    ocs_centos
else
    # Other way to determine Linux OS
    DISTRIB=`head -n1 /etc/issue | awk {'print $1'}`
    case $DISTRIB in
        Fedora) ocs_fedora;;
        CentOS) ocs_centos;;
        Red) ocs_centos;;
    esac
fi

# Delete these lines from rc.local
sed -i '/\/root\/install_mandriva_pulse2_inventory.sh/d' /etc/rc.local

# Once installed, delete this file
rm /root/install_mandriva_pulse2_inventory.sh
