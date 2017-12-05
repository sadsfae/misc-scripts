#!/bin/bash
# simple script to scrape DKP site and report value
# usage: sh report_dkp PLAYERNAME
args=$1
player_name=$(echo $args | awk '{ print $2 }')
dkp_url="https://example.com/eqdkp/index.php/Points/"

# minimal sanitization of input
# print usage if not specified
if [[ $# -eq 0 ]]; then
        echo "USAGE: report-dkp.sh PLAYERNAME (case sensitive) "
        echo "                                                 "
        exit 1
fi

function gather_dkp_value {
        obtain_dkp=$(curl --silent $dkp_url | egrep -A1 $player_name \
        | sed 's/<[^>]*>//g' | egrep -v "Main|--" | awk 'NR==3')
        dkp_value=$(echo $obtain_dkp | tr -d '[:blank:]')
        echo "$player_name currently has $dkp_value points"
}

playerdkp=$(gather_dkp_value)

cat <<EOF
{"response_type": "ephemeral", "text": "$(echo $playerdkp)"}
EOF
