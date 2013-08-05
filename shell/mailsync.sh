#!/bin/bash
# sync offlineimap if you're connected to a VPN
# also check if it's running (or hung) and kill it off first
imapactive=`ps -ef | grep offlineimap | grep -v grep | wc -l`
vpnactive=`/sbin/ifconfig -a | grep tun0 | wc -l`
mailsync="/usr/bin/offlineimap -u quiet -q"

# kill offlineimap if active, sometimes it hangs
case $imapactive in
'1')
   killall offlineimap && sleep 5
;;
esac

# if there's a TUN interface then sync mail bro
case $vpnactive in
'1')
   $mailsync
;;
esac
