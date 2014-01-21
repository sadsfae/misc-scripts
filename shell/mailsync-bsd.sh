#!/usr/local/bin/bash
# modified mailsync.sh to work on BSD
# syncs offlineimap

user=`whoami` 
imapactive=`ps -U $user | grep python2.7 | grep offlineimap | wc -l | awk '{print $1}'`
mailsync="/usr/local/bin/offlineimap -u quiet >/dev/null 2>&1"
offlineimap_pid=`ps -U $user | grep python2.7 | grep offlineimap | awk '{print $1}'`
# kill offlineimap if active, sometimes it hangs

case "$imapactive" in
'1')
   kill $offlineimap_pid && sleep 5
;;
esac

$mailsync
