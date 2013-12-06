#!/bin/bash
# GPG encrypt logfiles to send them to an FTP server
# this assumes a dedicated gpg key with no passphrase
# only use it for this purpose, it's just to encrypt across the wire.
# could be run once a day in cron via: * 11 * * * /opt/gpg-enc-files.sh >/dev/null 2>&1

# array of key id's to include
KEYIDS=(XXXXXXXX XXXXXXXX XXXXXXXX)

# logs to backup
logs=(/var/log/messages /var/log/secure /var/log/lastlog)

# date and time
backupdir='/root/log_backup'
date=`date +%d_%m_%Y`
logname=yourlogs
uploadlog='/var/log/log-upload.log'

# FTP credentials
FTPHOST=yourftp.example.com
FTPUSER=username
FTPPASS=userpass

# backup files and encrypt them
BACKUP_ENCRYPT= $( tar -cvz ${logs[*]} | gpg --encrypt --recipient ${KEYIDS[0]} --recipient ${KEYIDS[1]} --recipient
${KEYIDS[2]} --trust-model always > $backupdir/$yourlogs_$date.tar.gz.gpg )

# create backupdir if it doesn't exist
if ! [ -d $backupdir ]; then
     mkdir -p $backupdir
fi

# perform the backup and encryption
$BACKUP_ENCRYPT

# log this somewhere 
echo "gpg-enc-ftp-files.sh: completed encryption/backup of $yourlogs_$date.tar.gz.gpg" >> $uploadlog

# FTP logs to remote location
ftp -n $FTPHOST <<END_OF_SESSION
user $FTPUSER $FTPPASS
type binary
put $backupdir/$yourlogs_$date.tar.gz.gpg $backupdir/$yourlogs_$date.tar.gz.gpg
bye
END_OF_SESSION

# log this somewhere 
echo "gpg-enc-ftp-files.sh: completed upload of $yourlogs_$date.tar.gz.gpg to remote server" >> $uploadlog 

# remove logfiles older than 60 days
find $backupdir/ -type f -ctime +60 -exec rm -rf {} \;
echo "gpg-enc-ftp-files.sh: culling logfile archives older than 60days" >> $uploadlog
