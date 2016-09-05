#!/bin/bash
# finds clonebases without flexclone dependencies
# replace orahome/appltop with what makes sense for you
FILER="YOURFILER"

for vol in $(ssh root@$FILER df -h | grep clonebase | egrep -v '(snapshot|orahome|appltop)' | awk -F'/' '{print $3}'); do 
    ssh root@YOURFILER vol status $vol | \
    awk '
/^clonebase/ {printf "%s: ",$1}
/Volume has clones/ {gsub(/,/, ""); for(i=4;i<=NF;i++){printf "%s ", $i}}
END {printf "\n"}
'
done
