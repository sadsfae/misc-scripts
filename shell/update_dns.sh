#!/bin/sh
# script to call nsupdate to add or delete DNS entries
# intends to be run on localhost where named is running
# does not need a named reload

nsupdate=`which nsupdate`

########## FUNCTIONS ##########
dns_add_forward()
{  # use nsupdate to make forward dns entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $forwardzone
   update add $fqdnadd 300 A $ipaddr
   show
   send
   quit
END_OF_SESSION
}  

dns_add_reverse()
{   # use nsupdate to make reverse entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $reversezone
   update add $ipaddrreverse$arpa 300 PTR $fqdnadd
   show
   send
   quit
END_OF_SESSION
}

# delete forward dns function
dns_delete_forward()
{  # use nsupdate to delete existing entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $forwardzone
   update delete $fqdndelete A
   show
   send
   quit
END_OF_SESSION
}

# delete reverse dns function
dns_delete_reverse()
{   # use nsupdate to delete reverse entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $reversezone
   update delete $ipaddrreverse$arpa PTR
   show
   send
   quit
END_OF_SESSION
}

# reverse IP address function
reverse_ip() 
{   # take the result of $ipaddr and reverse it for in.arpa
    echo "$1" | awk 'BEGIN{FS=".";ORS="."} {for (i = NF; i > 0; i--){print $i}}'
}

########## END FUNCTIONS ##########

# sanity check to ensure user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# present action menu
cat <<Endofmessage

=========== DNS Updater 5000 ===========
Enter the appropriate action
----------------------------
1) Add New DNS Entry
2) Delete Existing DNS Entry
----------------------------
** Enter 1 or 2 **
========================================

Endofmessage

action=$(head -n1)

########## ADD NEW DNS ENTRY SECTION ##########

if [ $action = "1" ];
   then
cat <<Endofmessage
----------------------------------------
Enter short hostname to ADD.. e.g. host01
----------------------------------------
Endofmessage

fqdnadd=$(head -n1)

cat <<Endofmessage
----------------------------------------
Enter IP address for $fqdnadd
----------------------------------------
Endofmessage

ipaddr=$(head -n1)

cat <<Endofmessage
----------------------------------------
Enter zone name.. e.g. example.com 
----------------------------------------
Endofmessage

forwardzone=$(head -n1).
ipaddrreverse=$(reverse_ip $ipaddr)
arpa='in-addr.arpa.'
reversezone=$(reverse_ip $ipaddr | cut -d "." -f2-4).$arpa
fqdnadd=$fqdnadd.$forwardzone

cat <<Endofmessage

+ + + + + + + + + + + + + + + + + + + + +
You're about to ADD the following entry..
+ + + + + + + + + + + + + + + + + + + + +

(forward zone: $forwardzone)
$fqdnadd 300 A $ipaddr
- - - - - - - - - - - - - - - - - - - - - 
(reverse zone: $reversezone)
$ipaddrreverse$arpa 300 PTR $fqdnadd

+ + + + + + + + + + + + + + + + + + + + +
Are you sure?  (Y/N)
Endofmessage

confirm=$(head -n1)

# call functions 'dns_add_forward' and 'dns_add_reverse'
case $confirm in
'y')
   dns_add_forward
   dns_add_reverse
;;
esac

case $confirm in
'Y')
   dns_add_forward
   dns_add_reverse
;;
esac

# if input isn't yes quit after taunting user.
case $confirm in
'n')
   echo "fe.g, why don't you go cry about it some more on your blog!"
   exit 1
;;
esac

case $confirm in
'N')
   echo "How does it feel to le.g a life of dissapointment?"
   exit 1
;;
esac
fi

########## DELETE DNS ENTRY SECTION ##########

if [ $action = "2" ];
   then
cat <<Endofmessage
----------------------------------------
Enter short hostname to DELETE .. e.g. host01
----------------------------------------
Endofmessage

fqdndelete=$(head -n1)

cat <<Endofmessage
----------------------------------------
Enter IP address to DELETE for $fqdndelete
----------------------------------------
Endofmessage

ipaddr=$(head -n1)

cat <<Endofmessage
----------------------------------------
Enter zone name to DELETE entry from.. e.g. example.com 
----------------------------------------
Endofmessage

forwardzone=$(head -n1).
ipaddrreverse=$(reverse_ip $ipaddr)
arpa='in-addr.arpa.'
reversezone=$(reverse_ip $ipaddr | cut -d "." -f2-4).$arpa
fqdndelete=$fqdndelete.$forwardzone

cat <<Endofmessage

+ + + + + + + + + + + + + + + + + + + + +
You're about to DELETE the following entry..
+ + + + + + + + + + + + + + + + + + + + +

(forward zone: $forwardzone)
$fqdndelete 300 A $ipaddr
- - - - - - - - - - - - - - - - - - - - -
(reverse zone: $reversezone$arpa)
$ipaddrreverse$arpa 300 PTR $fqdndelete

+ + + + + + + + + + + + + + + + + + + + +
Are you sure?  (Y/N)
Endofmessage

confirmdelete=$(head -n1)

# call functions 'dns_delete_forward' and 'dns_delete_reverse'
case $confirmdelete in
'y')
   dns_delete_forward
   dns_delete_reverse
;;
esac

case $confirmdelete in
'Y')
   dns_delete_forward
   dns_delete_reverse
;;
esac

# if input isn't yes quit after a good insult.
case $confirmdelete in
'N')
   echo "Why don't you go cry about it on your blog then!"
   exit 1
;;
esac

case $confirmdelete in
'n')
   echo "your insolence is unacceptable!"
   exit 1
;;
esac
fi
