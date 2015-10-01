#!/bin/bash
# generate a simple HTML table with quakestat (qstat) data
# requires quakestat for HTML, convert and html2ps for image conversion
# I use the following .html2psrc
#BODY {
#     font-size: 16pt;
#     }

gameserver="example.com"
tmpfiles=(/tmp/et.txt /tmp/et.ps /tmp/et.html /tmp/etfull.txt)

qstat_cleanup() {
for i in ${tmpfiles[*]}; do
        if [ -e $i ]; then
                rm -f $i
        fi
done
}

qstat_generate() {
	# generate generic status
        /usr/bin/quakestat -woets $gameserver -P -raw "|" > /tmp/et.txt
	srv=`cat /tmp/et.txt | awk -F "|" 'NR==1{print $2}'`
	pc=`cat /tmp/et.txt | awk -F "|" 'NR==1{print $6}'`
	pclimit=`cat /tmp/et.txt | awk -F "|" 'NR==1{print $5}'`
	gmap=`cat /tmp/et.txt | awk -F "|" 'NR==1{print $4}'`
	gping=`cat /tmp/et.txt | awk -F "|" 'NR==1{print $7}'`
	srvtype=`cat /tmp/et.txt | awk -F "|" 'NR==1{print $3}'`

        # generate generic CSS template for status
        cat > /tmp/et.html <<EOF
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
    <th class="tg-edkc">MOD/TYPE</th>
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
    
    # generate player info and frags and append
    /usr/bin/quakestat -woets $gameserver -P | tail -n+3 > /tmp/etfull.txt 
    # replace 'frags' with 'experience' since that's what qstat reports
    sed -i -e 's/frags/experience/' /tmp/etfull.txt
    cat /tmp/etfull.txt | awk 'BEGIN{print "<table>"} {print "<tr>";for(i=1;i<=NF;i++)print \
		"<td>" $i"</td>";print "</tr>"} END{print "</table>"}' >> /tmp/et.html
    # HTML copy  
    cp /tmp/et.html /home/`whoami`/public_html/et.html
    # create image of HTML page
    /usr/bin/html2ps -F /tmp/et.html > /tmp/et.ps
    convert /tmp/et.ps /home/`whoami`/public_html/et.png
}

qstat_cleanup
qstat_generate
