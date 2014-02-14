#!/bin/sh
# combines txt files containing host/server information into trac wiki format
# this is for use in automatically generating server/infrastructure documentation
#####################################################
####  USAGE: ./tracwiki-table-generate.sh  <node> <rack>
####  -----------------------------------------------
####  For example, to generate an entire rack (nodes 1-34) for all of rack3
####  for x in $(seq 1 34); do sh ./tracwiki-table-generate.sh $x 3 ; done > /tmp/rack3-wiki.txt ; cat /tmp/rack3-wiki.txt | tac
#####################################################
####  ** you need the files below populated with the right info
####     however the script will create them for you initially
####  ** each file contains info on separate lines, where line1 is node1 (U1 in rack)
####  ----- FILES -----
####  ethmac.txt = MAC addresses of primary (PXE) interface  
####  hostname.txt = host's FQDN
####  hostnumber.txt = host number, e.g. 01, 02
####  ipmimac.txt = MAC addresses of IPMI/iDRAC
####  ipminame.txt = FQDN of IPMO/iDRAC
####  serial.txt = Serial number or Service tag of node
#####################################################
####  we use the following wiki table structure
####  "== Rack $racknumber ==
####  ||= Location =||= Type =||= Brand =||= Model =||= Serial # =||= Hostname =||= IP =||= MAC =||= IPMI Hostname =||= IPMI IP =||= IPMI MAC =||= Mgmt =||

nodeorder=${1}p
racknumber=$2
wikidir="/tmp/rack$racknumber"
resourcecheck=`cat $wikidir/*.txt 2> /dev/null | wc -l`

createwikidata() {
        cd /tmp/
	echo "rack$racknumber directory and files do not exist, creating.." 
	mkdir -p rack$racknumber
	echo "creating empty resource files in $wikidir, populate these before proceeding"
        touch rack$racknumber/{ethmac.txt,hostname.txt,hostnumber.txt,ipmimac.txt,ipminame.txt,serial.txt} 
}

if [[ ! -d /tmp/rack$2 ]] ; then
	createwikidata
   exit
fi

case $resourcecheck in
'0')
   echo "your resource files are empty, quitting!"
   exit
;;
esac

hostnumber() {
	cat $wikidir/hostnumber.txt | sed -n $nodeorder
}

serial() {
	cat $wikidir/serial.txt | sed -n $nodeorder
}

hostnames() {
	cat $wikidir/hostname.txt | sed -n $nodeorder
}

ethmac() {
	cat $wikidir/ethmac.txt | sed -n $nodeorder
}

ipminame() {
	cat $wikidir/ipminame.txt | sed -n $nodeorder
}

ipminamehttps() {
	cat $wikidir/ipminame.txt | sed 's/ipmi-/https:\/\/ipmi-/' | sed -n $nodeorder
}

ipmimac() {
	cat $wikidir/ipmimac.txt | sed -n $nodeorder
}

ipaddress() {
	host $(hostnames) | awk '{print $4}'
}

ipaddressipmi() {
	host $(ipminame) | awk '{print $4}'
}

printwiki() {
	echo "|| $(hostnumber) || system || Dell || R620 || $(serial) || $(hostnames) || $(ipaddress) || $(ethmac) || $(ipminamehttps) || $(ipaddressipmi) || $(ipmimac) || ||"
}

printwiki
