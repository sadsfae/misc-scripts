#!/bin/sh
# This will do the following
# 1) create a mysqldump archive of the running database
# 2) rsync contents of /var/www/html/eqdkp/ into a local git repo
# 3) push the copy to a remote, private git repo (I like gitlab.com)
# 4) remove copies older than 120 days locally.
# ---------------------------------------------
# requires binary logging to be enabled i.e.
# [mysqld]
# log-bin=mysql-bin
# call this in cron for once a day, etc.
# ---------------------------------------------
# 0 22 * * * /root/backups/bin/mysqldump-git-eqdkp.sh >/dev/null 2>&1

#### backup database ####

dump_date=$(/bin/date +%Y%m%d%H%M)
dump_dest='/srv/backup/eqdkp_backup'
mysqlpass="PASSWORD"
mysqldump=`which mysqldump`
mysqldump_opts='--all-databases --opt --single-transaction --master-data'
backuplog='/var/log/mysqldump-eqdkp.log'
expired_archives=`find $dump_dest -type f -ctime +120 -exec ls {} \;`
rmexpired_archives=`find $dump_dest -type f -ctime +120 -exec rm -rf {} \;`

if ! [ -d $dump_dest ]; then
     mkdir -p $dump_dest
fi

if [ -d $dump_dest ]; then
   echo "(`date`) mysqldump-eqdkp: backup starting: mysqldump-eqdkp-${dump_date}.gz" >> $backuplog
   $mysqldump --password="$mysqlpass" $mysqldump_opts | /usr/bin/gzip - > $dump_dest/mysqldump-eqdkp-${dump_date}.gz;
   echo "(`date`) mysqldump-eqdkp: backup complete: mysqldump-eqdkp-${dump_date}.gz" >> $backuplog
fi

# remove archives older than 120 days
echo "(`date`) mysqldump-eqdkp: removing archives older than 120 days:" >> $backuplog
for x in $expired_archives;
   do printf "(`date`) mysqldump-eqdkp: [removing] $x\n" >> $backuplog;
   $rmexpired_archives;
done

#### backup eqdkp data files ####

databackup="eqdkp-data"
eqdkpdata="/var/www/html/eqdkp"
function archive_files {
        rsync -av $eqdkpdata $gitorigin/$databackup/
}

#### Push to git ####

date=$(/bin/date +%Y%m%d%H%M)
gitorigin="/root/backups"
gitdest="eqdkp-db-backup/"

function backup_data {
        cd $gitorigin
        cp $dump_dest/mysqldump-eqdkp-${dump_date}.gz $gitdest
        git add $databackup/*
        git add $gitdest/mysqldump-eqdkp-${dump_date}.gz
        git commit -m "auto backup of eqdkp db/data on $date"
        git push
}

archive_files
backup_data
