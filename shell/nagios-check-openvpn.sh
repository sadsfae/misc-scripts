#!/bin/bash
# simple wrapper script to check open UDP port and capture status code 
# using nmap in this case because the community check_udp doesn't always work
# for every service.  In this case I'm using this for a simple openvpn response
# check
# Nagios talks status codes:
#
#    0 - Service is OK.
#    1 - Service has a WARNING.
#    2 - Service is in a CRITICAL status.
#    3 - Service status is UNKNOWN.
#
## VPN CHECK SETUP ##
# Requires: nrpe since this is client-side check
# Requires: nmap
# Requires: nrpe user with valid shell (unfortunately for now)
# e.g. chsh -s /bin/bash nrpe
# Requires: sudoers for running script & nmap
# e.g. 
# nrpe ALL = NOPASSWD:/usr/lib64/nagios/plugins/check_openvpn
# nrpe ALL = NOPASSWD:/usr/bin/nmap *
## NAGIOS SERVER SETUP ##
# 1) rename nagios-check-openvpn.sh to /usr/lib64/nagios/plugins/check_openvpn
# 2) add following line to nrpe.cfg:
#    command[check_openvpn]=/usr/bin/sudo /usr/lib64/nagios/plugins/check_openvpn
# 3) nagios server: add following line to /etc/nagios/conf.d/services.cfg:
#define service{
#        use                     generic-service
#        host_name               your-server-alias-name-in-nagios
#        service_description     OpenVPN Server
#        check_command           check_nrpe!check_openvpn
#}

HOST=localhost
PORT=1194
PORTSTATUS="open|filtered"
/usr/bin/nmap -sU -p $PORT -P0 $HOST | grep "$PORTSTATUS" 1>/dev/null 2>/dev/null && echo "OK: OpenVPN listening on UDP/$PORT" || { echo "CRITICAL: No Response"; exit 2; } 
