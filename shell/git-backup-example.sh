#!/bin/bash
# Example script to tar up files and push to
# remote git repo
#  http://hobo.house/2017/07/15/distributed-remote-backups-with-git-and-etckeeper/
# run once a day from cron
#0 11 * * * * sh /root/git-backup.sh >/dev/null 2>&1

date=$(/bin/date +%Y%m%d%H%M)
gitorigin="/root/backups/"
# this is a cloned remote repo
gitdest="vps-backup/"

function archive_files {
        tar cvf $gitorigin/vps-conf-backups-$date.tar \
        /etc/named.conf \
        /var/named/ \
        /etc/httpd/ \
        /etc/mail/ \
        /etc/opendkim/ \
        /etc/opendmarc.conf \
        /home/some_small_homedir
}

function backup_data {
        cd $gitorigin
        cp vps-conf-backups-$date.tar $gitdest
        cd $gitdest/
        git add vps-conf-backups-$date.tar
        git commit -m "auto backup of vps conf files $date"
        git push
}

archive_files
backup_data
