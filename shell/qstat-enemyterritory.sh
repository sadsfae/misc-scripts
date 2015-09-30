#!/bin/bash
# generate a simple HTML table with quakestat (qstat) data
# requires qstat
# requires convert (from imagemagick), html2ps for image conversion

gameserver="funcamp.net"

qstat_cleanup() {
	if [ -f /tmp/et.txt ]; then
		rm -f /tmp/et.txt
	fi
	if [ -f /tmp/et.html ]; then
		rm -f /tmp/et.html
	fi
	if [ -f /tmp/et.ps ]; then
		rm -f /tmp/et.ps
	fi
}

qstat_generate() {
	/usr/bin/quakestat -woets $gameserver -raw "|" > /tmp/et.txt
	srv=`cat /tmp/et.txt | awk -F "|" '{print $2}'`
	pc=`cat /tmp/et.txt | awk -F "|" '{print $6}'`
	pclimit=`cat /tmp/et.txt | awk -F "|" '{print $5}'`
	gmap=`cat /tmp/et.txt | awk -F "|" '{print $4}'`
	gping=`cat /tmp/et.txt | awk -F "|" '{print $7}'`
	srvtype=`cat /tmp/et.txt | awk -F "|" '{print $3}'`

	cat > /tmp/et.html <<EOF
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;border-color:#ccc;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:0px;overflow:hidden;word-break:normal;border-color:#ccc;color:#333;background-color:#fff;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:0px;overflow:hidden;word-break:normal;border-color:#ccc;color:#333;background-color:#f0f0f0;}
.tg .tg-edkc{font-size:28px;vertical-align:top}
.tg .tg-2rv1{font-size:32px;vertical-align:top}
.tg .tg-24i8{font-size:24px;vertical-align:top}
</style>
<table class="tg">
  <tr>
    <th class="tg-edkc">ADDRESS<br></th>
    <th class="tg-2rv1">PLAYERS</th>
    <th class="tg-edkc">MAP</th>
    <th class="tg-edkc">PING<br></th>
    <th class="tg-edkc">MOD/TYPE</th>
  </tr>
  <tr>
    <td class="tg-24i8">$srv</td>
    <td class="tg-24i8">$pc/$pclimit</td>
    <td class="tg-24i8">$gmap</td>
    <td class="tg-24i8">$gping</td>
    <td class="tg-24i8">$srvtype</td>
  </tr>
</table>
EOF
	/usr/bin/html2ps /tmp/et.html > /tmp/et.ps
	convert /tmp/et.ps /home/`whoami`/public_html/et.png
}

qstat_cleanup
qstat_generate
