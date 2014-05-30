#!/bin/sh
# this tool gives you an easy way to generage ifcfg-* on Linux machines
# when using bonding configs, our default is mode 4 for LACP
# this will create necessary bonding configs on a host if they are
# tagged on more than one VLAN.
# this could be done in kickstart %post but I like the option of doing it selectively.
# *** NOTE *** You MUST have the following pre-requisites
# 1) proper VLAN switch configuration in place for the node
# 2) DNS entries that exist on the correct network/map

bondinterface=bond0

#### FUNCTIONS START ####

vlan_determine()
{  # determine what VLAN isn't needed, return first three octets
   /sbin/ifconfig $bondinterface | grep Bcast | awk -F ":" '{print $2}' | awk '{print $1}' | awk -F "." '{print $1,$2,$3}' | sed 's/ /./g'
}

# set ip variable
ipaddr_short=$(vlan_determine)

# generate correct menu based on current ip address

vlan_minus_hadoop()
{  # generate vlan options minus hadoop
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(6) vlan 6  (cloudpub)  - 10.1.16.0/20
(8) vlan 8  (mgmt)      - 10.1.8.0/23
(9) vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv) - 172.16.0.0/18
--------------------------------------
===========================================
endofmessage

vlanadd=$(head -n1)
}

vlan_minus_cloudpub()
{  # generate vlan options minus cloudpub
cat <<endofmessage

=========== VLAN Helper 5000 ==============
specify the vlan number for config creation
--------------------------------------
(4) vlan 4  (hadoop)    - 10.1.4.0/22
(8) vlan 8  (mgmt)      - 10.1.8.0/23
(9) vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv) - 172.16.0.0/18
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
(4) vlan 4  (hadoop)    - 10.1.4.0/22
(6) vlan 6  (cloudpub)  - 10.1.16.0/20
(9) vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv) - 172.16.0.0/18
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
(4) vlan 4  (hadoop)    - 10.1.4.0/22
(6) vlan 6  (cloudpub)  - 10.1.16.0/20
(8) vlan 8  (mgmt)      - 10.1.8.0/23
(9) vlan 9  (rhev)      - 10.1.32.0/19
(16) vlan 16 (cloudprv) - 172.16.0.0/18
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
NETMASK=255.255.240.0
USERCTL=no
NOZEROCONF=yes
EOF
}

vlan_create_mgmt()
{  # create
cat > /tmp/ifcfg-mgmt << EOF
DEVICE=bond0.8
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
TYPE=Bridge
ONBOOT=yes
DELAY=0
BOOTPROTO=static
IPADDR=$vlanip
NETMASK=255.255.192.0
USERCTL=no
NOZEROCONF=yes
EOF
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

esac

# prompt for VLAN choice
vlanadd=$(head -n1)

# prompt for IP address of the VLAN
# this is 2/2 of the interactive menus
cat <<EndofMessage
=========== VLAN Helper 5000 ==============
Specify the full IP address for this node 
on VLAN $vlanadd
===========================================

EndofMessage

vlanip=$(head -n1)

# obtain bridge name from VLAN choice
if [ $vlanadd = "4" ]; then
   bridgename=hadoop
fi

if [ $vlanadd = "6" ]; then
   bridgename=cloudpub
fi

if [ $vlanadd = "8" ]; then
   bridgename=mgmt
fi

if [ $vlanadd = "9" ]; then
   bridgename=rhev
fi

if [ $vlanadd = "16" ]; then
   bridgename=cloudprv
fi

# refer to it's FQDN for the virtual interface
vlaniphost=`host $vlanip | awk '{print $NF}'`

# make DNS existence a 0 or 1 variable
vlaniphostdns=`host $vlanip | grep pointer | wc -l`

# cut ip address chosen down to first two octets
ipaddr_short_largenet=`echo $vlanip | awk -F "." '{print $1,$2}' | sed 's/ /./g'`

# ensure IP address has a valid DNS entry
# since 172.16.0.0/18 is not DNS managed we skip the check
if [ $ipaddr_short_largenet != '172.16' ]; then 
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
   exit 1
;;
esac
fi

# generate the correct VLAN config
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
esac
