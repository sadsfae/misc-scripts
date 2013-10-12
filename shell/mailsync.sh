#!/bin/bash
# sync offineimap when you can do a DNS lookup against your mailserver
# run this from cron, I use every 12min (*/12 * * * *)

imapactive=`ps -ef | grep offlineimap | grep -v grep | wc -l`
mailsync="/usr/bin/offlineimap -u quiet -q"
username=`whoami`
mailhost=`cat /home/$username/.offlineimaprc | grep remotehost | awk '{print $3}'`
online=`host $mailhost | grep "has address" | wc -l`

# kill offlineimap if active, in some rare cases it may hang
case $imapactive in
'1')
   killall offlineimap && sleep 5
;;
esac

# if you can do a DNS lookup, sync your mail
case $online in
'1')
   $mailsync
;;
esac
