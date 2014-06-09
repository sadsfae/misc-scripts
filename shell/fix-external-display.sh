#!/bin/sh
# original credit goes to this dude below, added small fix:
# Author: siddhesh.in
# http://tuxdna.wordpress.com/2011/11/17/how-to-setup-multiple-monitors-on-xfce-desktop/
# Execute it after connecting the display to your box:
 
typeset -a resx
typeset -a resy
typeset -a screen
typeset -i name=1
typeset -i count=0
 
tmpfile=$(mktemp)
cmd="xrandr --fb "
 
xrandr | grep -A 1 " connected " | grep -v "^--$" | awk '{print $1}' > $tmpfile
count=0
 
for line in $(cat $tmpfile); do
if [ $name -eq 1 ]; then
screen[$count]=$line
name=0
else
line=$(echo $line|sed 's/[Xx]/ /g')
resx[$count]=$(echo $line | awk '{print $1}')
resy[$count]=$(echo $line | awk '{print $2}')
count=$((count+1))
name=1
fi
done
 
total_width=0
prev_scr=
max_height=0
for i in $(seq 0 $((count-1))); do
if [ $max_height -lt ${resy[$i]} ]; then
max_height=${resy[$i]}
fi
 
cmd_ext="$cmd_ext --output ${screen[$i]} --mode ${resx[$i]}x${resy[$i]}"
if [ -n "$prev_scr" ]; then
cmd_ext="$cmd_ext --right-of $prev_scr"
fi
prev_scr=${screen[$i]}
 
total_width=$((total_width+${resx[$i]}))
done
 
cmd="xrandr --fb ${total_width}x${max_height} $cmd_ext"
 
echo "Running command: $cmd"
eval $cmd
 
rm -f tmpfile
