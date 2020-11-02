#!/bin/sh
echo "[Start eraselogs.sh]"
MINUTES=$(($1 * 60))
find /usr/vpnserver/server_log/ -name "*.log" -type f -mmin +$MINUTES -exec rm -f {} \;
find /usr/vpnserver/packet_log/ -name "*.log" -type f -mmin +$MINUTES -exec rm -f {} \;
find /usr/vpnserver/security_log/ -name "*.log" -type f -mmin +$MINUTES -exec rm -f {} \;
#rem
mkdir /$(date +%s)