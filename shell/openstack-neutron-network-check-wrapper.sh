#!/bin/bash
# wrapper script to put floating ip results in a file rather
# than burden your monitoring system with long timeouts
checker=/root/trystack-neutron-network-check.sh
resultfile=/etc/nagios/data/floating-ip-results
TMPFILE=$(mktemp /tmp/fip-checker-XXXXXX)

$checker 1>$TMPFILE 2>&1
rp=$?
echo $rp >> $TMPFILE
cat $TMPFILE > $resultfile
rm -f $TMPFILE

