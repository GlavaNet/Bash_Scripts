#!/bin/bash

# A script that checks if the system's public IP is your VPN provider's or not.
# If not, assumes OpenVPN service is not running or has crashed and restarts it.
# Sends tunnel-down alerts to a log with timestamps.
# Suggest scheduling in 10 minute intervals with cron.

# Initialize array
arr=( "any" "VPN" "only" "services" )

# Set variables
check="http://wtfismyip.com/text"

addr="enter.destination.ip.here"

log=/var/log/vpncheck.log

res=$(wget -qO - $check)

vpnsvc=$(ps -eaf | grep -i openvpn | sed '/^$/d' | wc -l)

# Check if our log file exists, and create it if not
if [[ ! -f $log ]]; then
    $(sudo touch $log)
fi

function killswitch_on {
  for i in "${arr[@]}"
  do
    svc=$(ps -eaf | grep -i $i | sed '/^$/d' | wc -l)
    if [ $svc > 0 ]; then
      sudo systemctl stop $i
    fi
  done
}

function killswitch_off {
  for i in "${arr[@]}"
  do
    svc=$(ps -eaf | grep -i $i | sed '/^$/d' | wc -l)
    if [ $svc < 1 ]; then
      sudo systemctl start $i
    elif [ $svc < 2 ]; then
      sudo systemctl restart $i
    fi
  done
}


function tunnel_check {
# If we don't have an IP address, log it
if [ -z $addr ]; then
  echo $(date -u) "Host has no IP address." >> $log
# If our IP address isn't our VPN provider's, log it and restart OpenVPN service
elif [ $res != $addr ]; then
  case $vpnsvc in
    0) echo $(date -u) "VPN tunnel has gone down - OpenVPN service not running! Starting..." >> $log
       killswitch_on
       sudo systemctl start openvpn
       if [ $vpnsvc > 1 ]; then
         echo $(date -u) "OpenVPN service successfully started. IP address is $addr." >> $log
         killswitch_off
       else
         echo $(date -u) "OpenVPN service failed to start, status $svc." >> $log
       fi;;
    1) echo $(date -u) "VPN tunnel has gone down - OpenVPN service has crashed! Restarting..." >> $log
       killswitch_on
       sudo systemctl stop openvpn && sudo systemctl start openvpn
       if [$svc > 1 ]; then
         echo $(date -u) "OpenVPN service successfully started. IP address is $addr." >> $log
         killswitch_off
       else
         echo $(date -u) "OpenVPN service failed to restart, status $svc." >> $log
       fi;;
  esac
fi
}
