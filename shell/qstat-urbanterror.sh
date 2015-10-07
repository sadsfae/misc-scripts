#!/bin/bash
# generate a simple HTML table with quakestat (qstat) data
# this will also parse logs and print recent players over past 24hrs
# requires quakestat for HTML, convert and html2ps for image conversion
# I use the following .html2psrc
#BODY {
#     font-size: 11pt;
#     }
####################### Example Pages:##################################
# http://funcamp.net/w/ut.html
# http://funcamp.net/w/ut.png
########################################################################
#   http://hobo.house/2015/10/03/play-urban-terror
########################################################################

gameserver="example.com"

# variables for qstat generation
UTHTML="/tmp/ut.html"
UTFULL="/tmp/utfull.txt"
UTTXT="/tmp/ut.txt"
UTPS="/tmp/ut.ps"
UTHOMEHTML="/home/`whoami`/public_html/ut.html"
UTHOMEIMG="/home/`whoami`/public_html/ut.png"

# variables for recent players
DATE=`date +%Y%m%d`
UTLOG="/home/`whoami`/UT/ut-server-$DATE.log"
UTPLAYERSTRIP="/tmp/utplayerstrip.txt"
UTPLAYERHTML="/tmp/utplayerstrip.html"
UTPLAYERSHORT="/tmp/utplayerstripshort.txt"

tmpfiles=($UTHTML $UTFULL $UTTXT $UTPS $UTPLAYERSTRIP \
          $UTPLAYERHTML $UTPLAYERSHORT)

cleanup_files() {
for i in ${tmpfiles[*]}; do
        if [ -e $i ]; then
                rm -f $i
        fi
done
}

qstat_generate() {
        # generate generic status
        /usr/bin/quakestat -q3s $gameserver -P -raw "|" > $UTTXT
        srv=`cat $UTTXT | awk -F "|" 'NR==1{print $2}'`
        pc=`cat $UTTXT | awk -F "|" 'NR==1{print $6}'`
        pclimit=`cat $UTTXT | awk -F "|" 'NR==1{print $5}'`
        gmap=`cat $UTTXT | awk -F "|" 'NR==1{print $4}'`
        gping=`cat $UTTXT | awk -F "|" 'NR==1{print $7}'`
        srvtype=`cat $UTTXT | awk -F "|" 'NR==1{print $3}'`

        # generate generic CSS template for status
        cat > $UTHTML <<EOF
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
        cat >> $UTHTML << EOF
<table class="tg">
  <tr>
    <th class="tg-edkc">Current Players<br></th>
</tr>
<br>
EOF

        # generate player info and frags and append
        /usr/bin/quakestat -q3s $gameserver -P | tail -n+3 > $UTFULL 
        cat $UTFULL | awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print \
	    "<td>" $i"</td>";print "</tr>"} END{print "</table>"}' >> $UTHTML 
}

daily_players() {
        # get list of daily players in form of when someone disconnects
        # we are stripping out bot names
        # note: Urban Terror doesn't allow space in names so we don't need additional awk
        cat $UTLOG | grep "disconnected" | egrep -v "Johnny|Galgoci|Dane|Donquaz|Toledo| \ 
            Dontavian" | awk '{print $3}' | sed 's/"//' | sed 's/\^7//' | sort | uniq -u > $UTPLAYERSHORT
}

generate_playerhtml() {
        # generate generic CSS for table title
        cat > $UTPLAYERHTML << EOF
<table class="tg">
  <tr>
    <th class="tg-edkc">Recent Players<br></th>
</tr>
<br>
EOF
        # generate nice HTML of recent players
        cat $UTPLAYERSHORT | awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print \
            "<td>" $i"</td>";print "</tr>"} END{print "</table>"}' >> $UTPLAYERHTML
}

html_convert() {
        # merge the two HTML files
        cat $UTPLAYERHTML >> $UTHTML  
        #HTML copy  
        cp $UTHTML $UTHOMEHTML
        # create image of HTML page
        /usr/bin/html2ps -F $UTHTML > $UTPS
        # remove old image, convert new one
        rm -f $UTHOMEIMG
        convert $UTPS $UTHOMEIMG
}

cleanup_files
qstat_generate
daily_players
generate_playerhtml
html_convert
