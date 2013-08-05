#!/bin/bash
# script to update a FreeBSD system using ZFS as root filesystem
# take a system ZFS snapshot then update system and ports/userland
# lastly, call portaudit to check for known CVE's

LOG_FILE="/var/log/freebsd-update.log"
ZFS_SNAP_DATE=`/bin/date +%Y%m%d%H%M`
ZFS_SNAP="zfs snapshot -r sys/ROOT/default@$ZFS_SNAP_DATE"
ZFS_SNAP_NAME="sys/ROOT/default@$ZFS_SNAP_DATE"

# check if the user is root, if not warn and quit
if [ "$(id -u)" != "0" ]; then
   echo "This action must be performed as root" 1>&2
   exit 1
fi

# take ZFS snapshot prior to updates
echo "Taking a ZFS snapshot called $ZFS_SNAP_NAME"
echo "***"
$ZFS_SNAP

# give some time for slower systems to return
sleep 5
echo "***"
echo "Done!"

# check for kernel/OS release updates
echo "Starting updates: `date`" | tee -a ${LOG_FILE}
echo "***"
echo "*** Checking for FreeBSD patches..."
echo "***"
/usr/sbin/freebsd-update fetch | tee -a ${LOG_FILE}
/usr/sbin/freebsd-update install | tee -a ${LOG_FILE}

# use portsnap to operate on fresh upstream ports tree
echo "***"
echo "*** Updating ports tree..."
echo "***"
/usr/sbin/portsnap fetch update | tee -a ${LOG_FILE}

# call portmaster to do the magic
echo "***"
echo "*** Looking for ports to update..."
echo "***"
/usr/local/sbin/portmaster -a -B --no-confirm | tee -a ${LOG_FILE}

# use portaudit to look for known CVE's or vulnerabilities post-update
# http://www.freshports.org/ports-mgmt/portaudit/
echo "***"
echo "*** Checking installed ports for known security problems..."
echo "***"
/usr/local/sbin/portaudit -Fva | tee -a ${LOG_FILE}
echo "Finished updates: `date`" | tee -a ${LOG_FILE}
