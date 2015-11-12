#!/bin/bash
# this is for Enemy Territory:Legacy running NQ with bots
# This will let you reset bot experience remotely
# this is a workaround to a bug in either ET:L, omni-bot
# or their implementation of it where bot say !resetmyxp doesn't work.
###### REQUIRES #####
# gcc
# https://github.com/acqu/wet-rcon-tool
# quakestat (qstat)
#####################
# you will need to compile the rcon binary, e.g.
# wget https://raw.githubusercontent.com/acqu/wet-rcon-tool/master/linux/rcon.c
# gcc -o rcon rcon.c 

# modify these to your liking
etserver='127.0.0.1'
etport='27960'
rconbin='/home/`whoami`/et/rcon'
rconpass='myrconpassword'

# obtain list of current bots
botlist=`quakestat -woets $etserver:$etport -P | egrep '\[BOT\]' | \
	grep frags | awk '{print $4}'`

# run reset command
for x in $botlist; do sleep 1; $rconbin --rcon="$etserver $etport $rconpass \
	resetxp $x"; sleep 1; done  
