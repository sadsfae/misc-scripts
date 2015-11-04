#!/bin/bash
DATE=`date +%Y%m%d`
DATE2=`date +%Y%m%d:%r`
SRVUSER=`whoiami`

# start that mug
./etlded +fs_gametype legacy +set dedicated 2 +set cg_countryflags 1 +set omnibot_path "./legacy/omni-bot" +set net_port
27961 +set omnibot_enable 1 +set omnibot_playing 1 +exec omnibot.cfg +exec omni-bot.cfg ttycon 0 +exec etl_server.cfg
1>>~/ETL/etl-server-$DATE.log 2>&1 &

# remove old symlink replace with latest log
rm /home/$SRVUSER/ETL/CURRENT_LOG >/dev/null 2>&1
ln -s /home/$SRVUSER/ETL/etl-server-$DATE.log /home/$SRVUSER/ETL/CURRENT_LOG
