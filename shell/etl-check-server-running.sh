#!/bin/bash
ETL_RUNNING=`ps -ef | grep etlded | grep -v grep|wc -l`
# example: https://github.com/sadsfae/misc-scripts/blob/master/shell/etl-start-server.sh
START_ETL='./etl_start_server.sh'

# If ETL: isn't running restart it
if [ $ETL_RUNNING = 0 ]; then
	   $START_ETL
   fi
      exit 0
