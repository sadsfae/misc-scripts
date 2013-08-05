#!/bin/bash
# script to update a FreeBSD system using ZFS as root filesystem
# take a system ZFS snapshot then update system and ports/userland
# lastly, call portaudit to check for known CVE's

LOG_FILE="/var/log/freebsd-update.log"
ZFS_SNAP_DATE=`/bin/date +%Y%m%d%H%M`
ZFS_SNAP="zfs snapshot -r sys/ROOT/default@$ZFS_SNAP_DATE"
ZFS_SNAP_NAME="sys/ROOT/default@$ZFS_SNAP_DATE"

echo "Taking a ZFS snapshot called $ZFS_SNAP_NAME"
echo "***"
$ZFS_SNAP
sleep 5
echo "***"
echo "Done!"

echo "Starting updates: `date`" | tee -a ${LOG_FILE}
echo "***"
echo "*** Checking for FreeBSD patches..."
echo "***"
/usr/sbin/freebsd-update fetch | tee -a ${LOG_FILE}
/usr/sbin/freebsd-update install | tee -a ${LOG_FILE}

echo "***"
echo "*** Updating ports tree..."
echo "***"
/usr/sbin/portsnap fetch update | tee -a ${LOG_FILE}

echo "***"
echo "*** Looking for ports to update..."
echo "***"
/usr/local/sbin/portmaster -a -B --no-confirm | tee -a ${LOG_FILE}

echo "***"
echo "*** Checking installed ports for known security problems..."
echo "***"
/usr/local/sbin/portaudit -Fva | tee -a ${LOG_FILE}
echo "Finished updates: `date`" | tee -a ${LOG_FILE}
