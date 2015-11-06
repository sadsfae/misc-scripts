#!/bin/bash
# written by: sadsfae (http://hobo.house)
#
# This tool generates a simple CSS/HTML table with quakestat (qstat) data
# of your Enemy Territory: Legacy server.
# http://www.etlegacy.com/
# It will also now parse logs and print recent players over past 24hrs
# or whenever your log file rotates or changes.
# -----------------------------------------------------------------------
# REQUIRES: quakestat (qstat) for stats, ImageMagick, html2ps for images
# REQUIRES: perl-Term-ANSIColor for stripping out ANSI in logs
# -----------------------------------------------------------------------
# There are parsing modifications needed for enemy territory:legacy that
# are not needed for normal enemy territory, particularly how we record
# "recent" players.
# 
# http://dev.etlegacy.com/projects/etlegacy/wiki/Links#section-3
# 
# EXAMPLE:
# http://eu.funcamp.net:9999/et.html
# http://eu.funcamp.net:9999/et.png
#
# For png generation:
# I use the following .html2psrc
#BODY {
#     font-size: 16pt;
#     }
#
# Startup and "check-running" tools might be useful as well:
# https://github.com/sadsfae/misc-scripts/blob/master/shell/etl-start-server.sh
# https://github.com/sadsfae/misc-scripts/blob/master/shell/etl-check-server-running.sh
#
# CRON Entry:
# --snip--
# SHELL=/bin/bash
# */3 * * * * cd /home/gaming_server/ETL/CURRENT && ./check_running.sh
# --snip--
# 
#
# Edit the below variables for your server environment and setup.
###############################################################################
# change this to your server
gameserver="example.com"

# variables for qstat generation
ETHTML="/tmp/et.html"
ETFULL="/tmp/etfull.txt"
ETTXT="/tmp/et.txt"
ETPS="/tmp/et.ps"

# change this accordingly, e.g. for Apache local public_html
# https://httpd.apache.org/docs/2.4/howto/public_html.html
# http://www.tuxradar.com/answers/457
ETHOMEHTML="/home/`whoami`/public_html/et.html"
ETHOMEIMG="/home/`whoami`/public_html/et.png"

# variables for recent players
DATE=`date +%Y%m%d`

# for me this is a symlink, see:
# https://github.com/sadsfae/misc-scripts/blob/master/shell/etl-start-server.sh
ETLOG="/home/`whoami`/ETL/CURRENT_LOG"
ETPLAYERLOG="/tmp/etplayers.txt"
ETPLAYERSTRIP="/tmp/etplayerstrip.txt"
ETPLAYERHTML="/tmp/etplayerstrip.html"
ETPLAYERSHORTRAW="/tmp/etplayerstripshortraw.txt"
ETPLAYERSHORT="/tmp/etplayerstripshort.txt"
ETPLAYERSHORTEAM="/tmp/etplayerstripteams.txt"

tmpfiles=($ETHTML $ETFULL $ETTXT $ETPS $ETPLAYERLOG $ETPLAYERSTRIP $ETPLAYERHTML \
	  $ETPLAYERSHORT $ETPLAYERSHORTRAW $ETPLAYERSHORTEAM)
###############################################################################

cleanup_files() {
for i in ${tmpfiles[*]}; do
        if [ -e $i ]; then
                rm -f $i
        fi
done
}

qstat_generate() {
    # generate generic status
    /usr/bin/quakestat -woets $gameserver -P -raw "|" > $ETTXT
    srv=`cat $ETTXT | awk -F "|" 'NR==1{print $2}'`
    pc=`cat $ETTXT | awk -F "|" 'NR==1{print $6}'`
    pclimit=`cat $ETTXT | awk -F "|" 'NR==1{print $5}'`
    gmap=`cat $ETTXT | awk -F "|" 'NR==1{print $4}'`
    gping=`cat $ETTXT | awk -F "|" 'NR==1{print $7}'`
    srvtype=`cat $ETTXT | awk -F "|" 'NR==1{print $3}'`

    # generate generic CSS template for status
    cat > $ETHTML <<EOF
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;border-color:#ccc;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:0px;overflow:hidden;word-break:normal;border-color:#ccc;color:#333;background-color:#fff;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:0px;overflow:hidden;word-break:normal;border-color:#ccc;color:#333;background-color:#f0f0f0;}
.tg .tg-edkc{font-size:28px;vertical-align:top}
.tg .tg-24i8{font-size:24px;vertical-align:top}
</style>
<table class="tg">
  <tr>
    <th class="tg-edkc">ADDRESS<br></th>
    <th class="tg-edkc">PLAYERS</th>
    <th class="tg-edkc">MAP</th>
    <th class="tg-edkc">PING<br></th>
    <th class="tg-edkc">SERVER NAME</th>
  </tr>
  <tr>
    <td class="tg-24i8">$srv</td>
    <td class="tg-24i8">$pc of $pclimit</td>
    <td class="tg-24i8">$gmap</td>
    <td class="tg-24i8">$gping</td>
    <td class="tg-24i8">$srvtype</td>
  </tr>
</table>
EOF

    # generate generic CSS for table title
    cat >> $ETHTML << EOF
<table class="tg">
  <tr>
    <th class="tg-edkc">Current Players<br></th>
</tr>
<br>
EOF
    
    # generate player info and frags and append
    /usr/bin/quakestat -woets $gameserver -P | tail -n+3 > $ETFULL 
    # replace 'frags' with 'experience' since that's what qstat reports
    sed -i -e 's/frags/experience/' /tmp/etfull.txt
    cat $ETFULL | awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print \
		"<td>" $i"</td>";print "</tr>"} END{print "</table>"}' >> $ETHTML 
}

daily_players() {
    # list of recent players in form of "broadcast: print "sadsfae joined the Allies team\n"
    # filter out bot names from showing up
    cat $ETLOG | grep "joined the" | egrep -v '\[BOT\]' | sort | uniq > $ETPLAYERLOG
    # strip out only the players names, this should also pick up spaces
    cat $ETPLAYERLOG | awk '{ if ($4 == "joined") { print $3 } else { print $3,$4}}' | \
		sed 's/"//' > $ETPLAYERSHORTRAW
    # because names and characters in logs contain ANSII characters they need to be stripped
    perl -e 'use Term::ANSIColor; print color "white"; print "ABC\n"; print color "reset";' | \
		perl -pe 's/\x1b\[[0-9;]*m//g' $ETPLAYERSHORTRAW > $ETPLAYERSHORTEAM
    # we might get matches for players joining both axis and allies, strip duplicates
    cat $ETPLAYERSHORTEAM | uniq  > $ETPLAYERSHORT
}

generate_playerhtml() {
    # generate generic CSS for table title
    cat > $ETPLAYERHTML << EOF
<table class="tg">
  <tr>
    <th class="tg-edkc">Recent Players<br></th>
</tr>
<br>
EOF
    # generate nice HTML of recent players
    cat $ETPLAYERSHORT | awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print \
        	"<td>" $i"</td>";print "</tr>"} END{print "</table>"}' >> $ETPLAYERHTML
}

html_convert() {
    # merge the two HTML files
    cat $ETPLAYERHTML >> $ETHTML  
    # HTML copy  
    cp $ETHTML $ETHOMEHTML
    # create image of HTML page
    /usr/bin/html2ps -F $ETHTML > $ETPS
    convert $ETPS $ETHOMEIMG
}

cleanup_files
qstat_generate
daily_players
generate_playerhtml
html_convert
