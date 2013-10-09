#!/bin/bash
# note changes in a file
# you need to know the md5sum of the watchfile
# change file or log variables to your liking

watchfile=/tmp/test.txt
logfile=/tmp/test.log
filemd5='d8e8fca2dc0f896fd7cb4cb0031ba249'
date=$(/bin/date +%Y%m%d-%M%S)
writelog="/usr/bin/echo '${watchfile} has changed on ${date}' >> ${logfile}"
unmodified=$(md5sum $watchfile | grep $filemd5 | wc -l)

# create watched file if it doesn't exist
if [ ! -e $watchfile ] ; then
   echo "your monitored file does not exist"
fi

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
