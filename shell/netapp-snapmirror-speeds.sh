#!/bin/bash
# get speeds of snapmirror transfers in KB based on an interval
# compare readings from snap delta amount transferred and do the math for us
FILER=$1
SLEEP_INTERVAL=30

function getstats {
(ssh -a root@$FILER snapmirror status -l) | awk '
$1 == "Source:"      {split($2,flop,":"); source=foo[2]}
$1 == "Destination:" {split($2,flop,":"); destination=foo[2]}
$1 == "Status:"      {status=$2}
$1 == "Progress:"    {progress=$2}
$1 == "State:"       {state=$2;
                      if ( status == "Transferring" ){
                          if ( state == "Source" ){
                              printf "%s=%d\n", source, progress;
                          } else {
                              printf "%s=%d\n", destination, progress;
                          }
                      }}
'
}

function calculate_speed {
old=$1
new=$2
interval=$3

declare keys
declare old_arr

i=0
for flop in $old; do
  keys[$i]=${flop%=*}
  old_arr[$i]=${flop#*=}
  i=$(($i+1))
done

i=0
for flop in $new; do
  echo "${keys[$i]}: $(( (${flop#*=} - ${old_arr[$i]}) / $interval )) KB/s"
  i=$(($i+1))
done
}

echo -n "Getting first statistics... "
run1="$(getstats)"
echo "done."
echo -n "Sleeping for $SLEEP_INTERVAL seconds... "
sleep $SLEEP_INTERVAL
echo "OK"
echo -n "Getting second statistics... "
run2="$(getstats)"
echo "done."

calculate_speed "$run1" "$run2" $SLEEP_INTERVAL
