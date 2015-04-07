#!/bin/bash
# archive and encrypt a file or directory
#
# USAGE :: ./backup-file.sh $BACKUPDIR $LOCALDATA $ARCHIVENAME
#       ::
#       :: ./backup-file.sh ~/Dropbox /tmp/backups backup01

remote_data=$1
local_data=$2
local_data_name=$3

# print usage if not specified
if [[ $# -eq 0 ]]; then
        echo "USAGE: ./backup-file.sh \$BACKUPDIR \$LOCALDATA \$ARCHIVENAME"
        echo "       ./backup-file.sh ~/Dropbox/backup /tmp/backups backup01"
	echo "                                          "
	exit 1
fi

# check if local_data dir exists
if [[ ! -d $2 ]]; then
        echo "local directory $2 does not exist, creating!"
        mkdir -p $2
fi

# if local_data is unable to be created, quit
if [[ ! -d $2 ]]; then
        echo "unable to create $2, check permissions."
        exit 1
fi

myrecipient='XXXXXXXX'

encrypt_data() {
	echo "backing up $local_data to $remote_data.."
	tar -cvz $local_data | gpg -e -r $myrecipient > $remote_data/$local_data_name.tar.gz.gpg
	echo "                                                "
	echo "backup: $remote_data/$local_data_name.tar.gz.gpg"
	echo "                                                "
}

encrypt_data
