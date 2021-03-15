#!/bin/bash

# Checks the status of services populated in an array. Starts or restarts them if they are not actively running.
# Schedule this script to run regularly with cron.
# Useful for services you want to ensure are always running, like FreeRADIUS, Oxidized, OpenVPN, etc.

# Declare array
arr=( "freeradius" "oxidized" "openvpn" )

# Check on status of our services, start or restart them if possible
for i in "${arr[@]}" 
  do
  # Get the status code of the service from systemctl
  svc=$(ps -eaf | grep -i $i | sed '/^$/d' | wc -l)
  case $svc in
    0) echo "$i is not running, let's start it."
       sudo systemctl start $i &&
       if [[ $svc > 1 ]]; then
         echo "$i successfully started with status $svc."
       else
         echo "$i returned status $svc."
       fi
    ;;
    1) echo "$i may have failed, let's restart it."
       sudo systemctl restart $i &&
       if [[ $svc > 1 ]]; then
         echo "$i successfully restarted with status $svc."
       else
         echo "$i returned status $svc."
       fi
    ;;
    2) echo "$i is running with status $svc."
    ;;
  esac
done
