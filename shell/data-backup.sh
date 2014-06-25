#!/usr/bin/sh
# backup critical config files locally and offsite somewhere
# in this particular example it does the following:
# 1) calls "mysqldump-foreman.sh" to take a MySQL dump of Foreman DB
# 2) tars up critical config and Foreman/Puppet files
# 3) places a copy locally, and sends a copy elsewhere via FTP
# 4) removes local files older than 60days
# does same thing as gpg-enc-ftp-files.sh but without GPG encryption over the wire.
# 0 11 * * * /usr/local/bin/data-backup.sh >/dev/null 2>&1

foreman_backup=`/usr/local/bin/mysqldump-foreman.sh`
backupdir='/srv/backup/foreman_backup'
date=`date +%d_%m_%Y_%H_%M`
backuplog='/var/log/config-backup.log'
backupname=foreman-configs

# files to backup
files=( /var/named $foreman_backup /etc /usr/share/foreman-proxy /var/lib/foreman /usr/share/foreman-installer /etc/puppet/environments /usr/share/foreman /opt/rh/ruby193 /usr/share/openstack-foreman-installer/puppet/modules /usr/share/packstack/modules )

# FTP credentials
# see password file
FTPHOST=ftp.example.com
FTPUSER=username
FTPPASS=password

# backup files and encrypt them
function BACKUP_FILES {
  echo running : tar -czf $backupdir/${backupname}_$date.tar.gz ${files[*]}
  tar -czf $backupdir/${backupname}_$date.tar.gz ${files[*]}
}

# create backupdir if it doesn't exist
if ! [ -d $backupdir ]; then
     mkdir -p $backupdir
fi

# perform the backup and encryption
BACKUP_FILES

# logging 
echo "data-backup.sh: completed backup of ${backupname}_$date.tar.gz" >> $backuplog

# FTP logs to remote location
ftp -n $FTPHOST <<END_OF_SESSION
user $FTPUSER $FTPPASS
type binary
put $backupdir/${backupname}_$date.tar.gz ${backupname}_$date.tar.gz
bye
END_OF_SESSION

# logging
echo "backup-data.sh: completed upload of ${backupname}_$date.tar.gz to remote server" >> $backuplog 

# remove logfiles older than 60 days
find $backupdir/ -type f -ctime +60 -exec rm -rf {} \;
echo "backup-data.sh: culling logfile archives older than 60days" >> $backuplog 
