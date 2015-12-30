#!/bin/bash
ip=$1
[ -z $ip ] && ip="192.168.71.200"
options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
sshpass="sshpass -p 'user'"
sshpass -p user scp -r $options user@$ip:/usr/lib/python2.7/dist-packages/\* usr/lib/python2.7/dist-packages/
sshpass -p user scp -r $options user@$ip:/usr/sbin/davos usr/sbin/
sshpass -p user scp -r $options user@$ip:/usr/sbin/fake_partclone usr/sbin/
sshpass -p user scp -r $options user@$ip:/usr/sbin/davos_postimaging usr/sbin/
sshpass -p user scp -r $options user@$ip:/usr/sbin/partclone_wrapper usr/sbin/
