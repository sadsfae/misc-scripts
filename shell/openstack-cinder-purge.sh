#!/bin/sh
# purge cinder volumes after 48hours
# cron entry:
#SHELL=/bin/bash
#PATH=/sbin:/bin:/usr/sbin:/usr/bin
#MAILTO=root
#28 * * * * root /root/cinder-purge.sh 1>/dev/null 2>&1

# 48hours in seconds == 172800
TTL=172800

for cindervol in $(cinder list --all-tenants | grep available | awk '{ print $2 }') ; do
  if [ "$(cinder show $cindervol | grep attachments | awk '{ print $4 }')" == "[]" ]; then 
    if [ $(expr $(date +%s) - $(date -d "$(cinder show $cindervol | grep created_at | awk '{ print $4 }')" +%s)) -gt $TTL ]; then
      for snap in $(cinder snapshot-list --all-tenants | sed '1,3d' | sed '$,$d' | grep $cindervol | awk '{ print $2 }') ; do 
        cinder snapshot-delete $snap
      done
      cinder delete $cindervol
    fi
  fi
done

