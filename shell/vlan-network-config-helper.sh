#!/bin/sh
# this tool gives you an easy way to generage ifcfg-* on Linux machines
# when using bonding configs, our default is mode 4 for LACP
# this will create necessary bonding configs on a host if they are
# tagged on more than one VLAN.
# this could be done in kickstart %post but I like the option of doing it selectively.
# *** NOTE *** You MUST have the following pre-requisites
# 1) proper VLAN switch configuration in place for the node
# 2) DNS entries that exist on the correct network/map
# ** the 172.16.0.0/18 network does not check for valid DNS

bondinterface=bond0

#### FUNCTIONS START ####

vlan_determine()
{  # determine what VLAN isn't needed, return first three octets
   /sbin/ifconfig $bondinterface | grep Bcast | awk -F ":" '{print $2}' | awk '{print $1}' | awk -F "." '{print $1,$2,$3}' | sed 's/ /./g'
}

ip_free()
{  # determine if ip address chosen is being used or not
   ping -c1 $vlanip | grep 'received' | awk -F',' '{print $2}' | awk '{print $1}'
}

# set ip variable
ipaddr_short=$(vlan_determine)

# generate correct menu based on current ip address

vlan_minus_dev()
{  # generate vlan options minus dev vlan
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(4)  vlan 4  (hadoop)    - 10.1.4.0/22
(6)  vlan 6  (cloudpub)  - 10.1.16.0/20
(5)  vlan 5  (mgmt)      - 10.1.8.0/23
(9)  vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv)  - 172.16.0.0/18
(18) vlan 18 (dev2)      - 10.1.253.0/28
(19) vlan 19 (dev3)      - 10.1.253.16/28
--------------------------------------
===========================================
endofmessage
}

vlan_minus_dev2()
{  # generate vlan options minus dev vlan
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(4)  vlan 4  (hadoop)    - 10.1.4.0/22
(6)  vlan 6  (cloudpub)  - 10.1.16.0/20
(5)  vlan 5  (mgmt)      - 10.1.8.0/23
(9)  vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv)  - 172.16.0.0/18
(19) vlan 19 (dev3)      - 10.1.253.16/28
--------------------------------------
===========================================
endofmessage
}

vlan_minus_dev3()
{  # generate vlan options minus dev vlan
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(4)  vlan 4  (hadoop)    - 10.1.4.0/22
(6)  vlan 6  (cloudpub)  - 10.1.16.0/20
(5)  vlan 5  (mgmt)      - 10.1.8.0/23
(9)  vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv)  - 172.16.0.0/18
(18) vlan 18 (dev2)      - 10.1.253.0/28
--------------------------------------
===========================================
endofmessage
}

vlan_minus_hadoop()
{  # generate vlan options minus hadoop
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(6)  vlan 6  (cloudpub)  - 10.1.16.0/20
(5)  vlan 5  (mgmt)      - 10.1.8.0/23
(9)  vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv)  - 172.16.0.0/18
(17) vlan 17 (dev)       - 10.1.254.0/24
(18) vlan 18 (dev2)      - 10.1.253.0/28
(19) vlan 19 (dev3)      - 10.1.253.16/28
--------------------------------------
===========================================
endofmessage

}

vlan_minus_cloudpub()
{  # generate vlan options minus cloudpub
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(4)  vlan 4  (hadoop)    - 10.1.4.0/22
(5)  vlan 5  (mgmt)      - 10.1.8.0/23
(9)  vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv)  - 172.16.0.0/18
(17) vlan 17 (dev)       - 10.1.254.0/24
(18) vlan 18 (dev2)      - 10.1.253.0/28
(19) vlan 19 (dev3)      - 10.1.253.16/28
--------------------------------------
===========================================
endofmessage
}

vlan_minus_mgmt()
{  # generate vlan options minus mgmt
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(4)  vlan 4  (hadoop)    - 10.1.4.0/22
(6)  vlan 6  (cloudpub)  - 10.1.16.0/20
(9)  vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv)  - 172.16.0.0/18
(17) vlan 17 (dev)       - 10.1.254.0/24
(18) vlan 18 (dev2)      - 10.1.253.0/28
(19) vlan 19 (dev3)      - 10.1.253.16/28
--------------------------------------
===========================================
endofmessage
}

vlan_minus_rhev()
{  # generate vlan options minus rhev
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(4)  vlan 4  (hadoop)    - 10.1.4.0/22
(6)  vlan 6  (cloudpub)  - 10.1.16.0/20
(5)  vlan 5  (mgmt)      - 10.1.8.0/23
(9)  vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv)  - 172.16.0.0/18
(17) vlan 17 (dev)       - 10.1.254.0/24
(18) vlan 18 (dev2)      - 10.1.253.0/28
(19) vlan 19 (dev3)      - 10.1.253.16/28
--------------------------------------
===========================================
endofmessage
}

vlan_create_hadoop()
{  # generate ifcfg-bond0.4 (hadoop)
cat > /tmp/ifcfg-bond0.4 <<EOF
DEVICE=bond0.4
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
BRIDGE=hadoop
EOF
}

vlan_create_hadoop_bridge()
{  # generate ifcfg-hadoop
cat > /tmp/ifcfg-hadoop << EOF
DEVICE=hadoop
TYPE=Bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=255.255.252.0
USERCTL=no
NOZEROCONF=yes 
EOF
}

vlan_create_cloudpub()
{  # generage ifcfg-bond0.6
cat > /tmp/ifcfg-bond0.6 << EOF
DEVICE=bond0.6
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
BRIDGE=cloudpub
EOF
}

vlan_create_cloudpub_bridge()
{  # generage ifcfg-cloudpub
cat > /tmp/ifcfg-cloudpub << EOF
DEVICE=cloudpub
TYPE=Bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=255.255.255.240
USERCTL=no
NOZEROCONF=yes
EOF
}

vlan_create_mgmt()
{  # create
cat > /tmp/ifcfg-mgmt << EOF
DEVICE=bond0.5
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
BRIDGE=mgmt
EOF
}

vlan_create_mgmt_bridge()
{  # generage ifcfg-mgmt
cat > /tmp/ifcfg-mgmt << EOF
DEVICE=mgmt
TYPE=Bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=255.255.254.0
USERCTL=no
NOZEROCONF=yes
EOF
}

vlan_create_cloudprv()
{  # generage ifcfg-bond0.16
cat > /tmp/ifcfg-bond0.16 << EOF
DEVICE=bond0.16
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
BRIDGE=cloudprv
EOF
}

vlan_create_cloudprv_bridge()
{  # generage ifcfg-cloudprv
cat > /tmp/ifcfg-cloudprv << EOF
DEVICE=cloudprv
TYPE=bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=255.255.192.0
USERCTL=no
NOZEROCONF=yes
EOF
}

vlan_create_dev()
{  # generage ifcfg-bond0.17
cat > /tmp/ifcfg-bond0.17 << EOF
DEVICE=bond0.17
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
BRIDGE=dev
EOF
}

vlan_create_dev_bridge()
{  # generage ifcfg-cloudprv
cat > /tmp/ifcfg-dev << EOF
DEVICE=dev
TYPE=bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=255.255.255.0
USERCTL=no
NOZEROCONF=yes
EOF
}

vlan_create_dev2()
{  # generage ifcfg-bond0.17
cat > /tmp/ifcfg-bond0.18 << EOF
DEVICE=bond0.18
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
BRIDGE=dev2
EOF
}

vlan_create_dev2_bridge()
{  # generage ifcfg-dev2
cat > /tmp/ifcfg-dev2 << EOF
DEVICE=dev2
TYPE=bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=255.255.255.240
USERCTL=no
NOZEROCONF=yes
EOF
}

vlan_create_dev3()
{  # generage ifcfg-bond0.19
cat > /tmp/ifcfg-bond0.19 << EOF
DEVICE=bond0.19
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
BRIDGE=dev3
EOF
}

vlan_create_dev3_bridge()
{  # generage ifcfg-dev3
cat > /tmp/ifcfg-dev3 << EOF
DEVICE=dev3
TYPE=bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=255.255.255.240
USERCTL=no
NOZEROCONF=yes
EOF
}

vlan_create_native()
{ # generate ifcfg-bond0 
cat > /tmp/ifcfg-bond0 << EOF
DEVICE=bond0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=CHANGEME
BONDING_OPTS="mode=4 miimon=500"
ONBOOT=yes
USERCTL=no
NOZEROCONF=yes
EOF

mynetmask=`grep NETMASK /tmp/ifcfg-$bridgename`

sed -i -e "s/^NETMASK=CHANGEME/$mynetmask/g" /tmp/ifcfg-bond0

}

#### END FUNCTIONS ####

# take input from vlan_determine() and print what we need
# this will create 1/2 of the interactive menus
case $ipaddr_short in
'10.1.4')
	vlan_minus_hadoop
;;

'10.1.16')
	vlan_minus_cloudpub
;;

'10.1.8')
	vlan_minus_mgmt
;;

'10.1.32')
	vlan_minus_rhev
;;

'10.1.254')
	vlan_minus_dev
;;

'10.1.253.0')
	vlan_minus_dev2
;;

'10.1.253.16')
	vlan_minus_dev3
;;
esac

# prompt for VLAN choice
#vlanadd=$(head -n1)
read vlanadd

echo "Generate configs for native VLAN [ y/n ]?"
echo "                                         "
#vlannative=$(head -n1)
read vlannative

# sanity check for vlan native

if [ $vlannative != 'y' ] && \
   [ $vlannative != 'Y' ] && \
   [ $vlannative != 'n' ] && \
   [ $vlannative != 'N' ] ; then 

   echo "You must select 'y' or 'n'"
   exit 1
fi

# obtain gateway for dev vlans
case $vlanadd in
'18')
    vlandevgateway='10.1.253.15'
;;
'19')
    vlandevgateway='10.1.253.30'
;;
esac

# prompt for IP address of the VLAN
# this is 2/2 of the interactive menus
cat <<EndofMessage
=========== VLAN Helper 5000 ==============
Specify the full IP address for this node 
on VLAN $vlanadd
===========================================

EndofMessage

#vlanip=$(head -n1)
read vlanip

echo "---------------------------------"
echo "checking if address is in use..."

# obtain bridge name from VLAN choice
if [ $vlanadd = "4" ]; then
   bridgename=hadoop
fi

if [ $vlanadd = "6" ]; then
   bridgename=cloudpub
fi

if [ $vlanadd = "5" ]; then
   bridgename=mgmt
fi

if [ $vlanadd = "9" ]; then
   bridgename=rhev
fi

if [ $vlanadd = "16" ]; then
   bridgename=cloudprv
fi

if [ $vlanadd = "17" ]; then
   bridgename=dev
fi

if [ $vlanadd = "18" ]; then
   bridgename=dev2
fi

if [ $vlanadd = "19" ]; then
   bridgename=dev3
fi

# refer to it's FQDN for the virtual interface
vlaniphost=`host $vlanip | awk '{print $NF}'`

# make DNS existence a 0 or 1 variable
vlaniphostdns=`host $vlanip | grep pointer | wc -l`

# cut ip address chosen down to first two octets
ipaddr_short_largenet=`echo $vlanip | awk -F "." '{print $1,$2}' | sed 's/ /./g'`

# ensure IP address has a valid DNS entry
# since 172.16.0.0/18 is not DNS managed we skip the check
# since VLANS 17, 18, 19 are not DNS managed we'll skip the check
if [ $ipaddr_short_largenet != '172.16' ] && \
   [ $ipaddr_short != '10.1.254' ] && \
   [ $ipaddr_short != '10.1.253' ] && \
   [ $vlanadd != '17' ] && \
   [ $vlanadd != '18' ] && \
   [ $vlanadd != '19' ]; then 

case $vlaniphostdns in
'1')
   echo "---------------------------------"
   echo "checking for valid reverse DNS..."
   echo "done, proceeding."
   echo "---------------------------------"
;;
'0')
   echo "---------------------------------"
   echo "----------!! ERROR !!------------"
   echo "no valid DNS entry found for this address"
   echo "why don't you cry about it on twitter?"
   echo "                                 "
   exit 1
;;
esac
fi

# if IP is in use, warn and quit after taunting user
case $(ip_free) in
'0')
   echo "IP address $vlanip seems free.   "
   echo "---------------------------------"
;;
'1')
   echo "---------------------------------"
   echo "----------!! ERROR !!------------"
   echo "IP address $vlanip is in use by something"
   echo "have you instead considered a career in crocodile wrestling?"
   echo "                                 "
   exit 1
;;
esac

# generate the correct VLAN config

if [ $vlannative != "y" ] && [ $vlannative != "Y" ]; then

cat <<EndofMessage

===================================================
---------------------------------------------------
VLAN configs for $vlanip on VLAN: $vlanadd created
for $vlaniphost

1) /tmp/ifcfg-bond0.$vlanadd
2) /tmp/ifcfg-$bridgename

** copy these into place after review **

cp /tmp/ifcfg-bond0.$vlanadd /etc/sysconfig/network-scripts/
cp /tmp/ifcfg-$bridgename /etc/sysconfig/network-scripts/

** issue 'service network restart' to take effect
---------------------------------------------------
===================================================

EndofMessage

else

cat <<EndofMessage

===================================================
---------------------------------------------------
VLAN configs for $vlanip on NATIVE VLAN: $vlanadd 
created for $vlaniphost

1) /tmp/ifcfg-bond0

** copy this into place after review **

cp /tmp/ifcfg-bond0 /etc/sysconfig/network-scripts/

2) EDIT your gateway to reflect the right native VLAN 

sed -i 's/GATEWAY=.*$/GATEWAY=$vlandevgateway

** issue 'service network restart' to take effect
---------------------------------------------------
===================================================

EndofMessage

fi

case $vlanadd in
'4')
   vlan_create_hadoop
   vlan_create_hadoop_bridge
;;
'6')
   vlan_create_cloudpub
   vlan_create_cloudpub_bridge
;;
'8')
   vlan_create_mgmt
   vlan_create_mgmt_bridge
;;
'16')
   vlan_create_cloudprv
   vlan_create_cloudprv_bridge
;;
'17')
   vlan_create_dev 
   vlan_create_dev_bridge
;;
'18')
   vlan_create_dev2
   vlan_create_dev2_bridge
;;
'19')
   vlan_create_dev3
   vlan_create_dev3_bridge
;;
esac

if [ "$vlannative" == "y" ] || [ "$vlannative" == "Y" ]; then
  vlan_create_native
fi

