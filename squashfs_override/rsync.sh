#!/bin/bash
options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
scp -r $options . user@192.168.71.202:/tmp/
ssh -r $options ssh user@192.168.71.202 "cp -rf /tmp/davos/* /"
