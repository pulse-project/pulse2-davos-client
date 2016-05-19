#!/bin/bash

source /etc/ocsinventory-client/periodic.conf

CURRENT_HOUR=`date '+%H'`

# Let's hack LAST_HOUR
if [ $CURRENT_HOUR -lt $LAST_HOUR ]; then
  LAST_HOUR=`expr $LAST_HOUR - 24`
fi

# Compute delta
TPM=`expr $CURRENT_HOUR - $LAST_HOUR`

# Create a random "wait time" to avoid all OSX reporting inventories at the same
# Randomized through time
RANDOM=$$$(date %+s)
# Between 1 and 20 (minutes)
D=$[ ( $RANDOM % 20  ) + 1 ]
# x 60, turn it into seconds
D=`expr $D \* 60`

# Delta > PROLOG_HOUR, time to start an inventory
if [ $TPM -ge $PROLOG_HOUR ]; then
  # Sleep some random time
  sleep $D
  # Start inventory
  /usr/local/sbin/ocs_mac_agent.php >/dev/null
  # Fix LAST_HOUR in periodic.conf
  sed -i -e "s/^LAST_HOUR=.*/LAST_HOUR=$CURRENT_HOUR/" /etc/ocsinventory-client/periodic.conf
fi
