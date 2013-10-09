#!/bin/bash
# note changes in a file
# you need to know the md5sum of the watchfile
# change watchfile or logfile variables to suit your needs

watchfile=/tmp/test.txt
logfile=/tmp/test.log
filemd5='76f0aa47381d7ee6e20ec3a9b11aecab'
date=$(/bin/date +%Y%m%d-%M%S)
writelog="/usr/bin/echo '${watchfile} has changed on ${date}' >> ${logfile}"
unmodified=$(md5sum $watchfile | grep $filemd5 | wc -l)

# fail and alert if the watchfile does not exist
{
if [ ! -f $watchfile ]; then
    echo "your watched file does not exist, create it and note md5sum"
    exit 0
fi
}

# create logfile if it doesn't exist
if [ ! -e $logfile ] ; then
   echo "creating log file $logfile" && touch $logfile
fi

# log if the file has changed
case $unmodified in
'0')
   $writelog
;;
esac
